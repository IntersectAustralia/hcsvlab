require 'linkeddata'
require 'xmlsimple'
require "#{Rails.root}/app/helpers/blacklight/catalog_helper_behavior.rb"
require "#{Rails.root}/app/helpers/blacklight/blacklight_helper_behavior"
require "#{Rails.root}/lib/rdf-sesame/hcsvlab_server.rb"

Dir["#{Rails.root}/lib/rdf/**/*.rb"].each {|f| require f}

#
# Solr_Worker
#
class Solr_Worker < ApplicationProcessor

  include Blacklight::CatalogHelperBehavior
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  #
  # =============================================================================
  # Configuration
  # =============================================================================
  #

  #
  # Load up the facet fields from the supplied config
  #
  def self.load_config
    @@configured_fields = Set.new
    FACETS_CONFIG[:facets].each do |aFacetConfig|
      @@configured_fields.add(aFacetConfig[:name])
    end
  end

  FACETS_CONFIG = YAML.load_file(Rails.root.join("config", "facets.yml")) unless const_defined?(:FACETS_CONFIG)
  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless const_defined?(:SESAME_CONFIG)

  load_config
  subscribes_to :solr_worker

  #
  # End of Configuration
  # -----------------------------------------------------------------------------
  #



  #
  # =============================================================================
  # Processing
  # =============================================================================
  #

  #
  # Deal with an incoming message
  #
  def on_message(message)
    # Expect message to be a command verb followed by the name of a Fedora object
    # and then do what the verb says to the object. Complain if the message is
    # badly formed, or we don't understand the command verb.
    
    info("Solr_Worker", "received: #{message}")
    parse = message.split(' ')

    if parse.size != 2
       error("Solr_Worker", "badly formatted instruction, expecting 'command object'")
       return
    end

    command = parse[0]
    object = parse[1]

    case command
    when "index"
      index_item(object)
    when "delete"
      delete(object)
    else
      error("Solr_Worker", "unknown instruction: #{command}")
      return
    end

  end

private


  #
  # =============================================================================
  # Indexing
  # =============================================================================
  #

  #
  # Do the indexing for an Item
  #
  def index_item(object)
    fed_item = Item.find(object)
    collection = fed_item.collection

    begin
      server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
      repository = server.repository(collection.name)
      raise Exception.new "Repository not found - #{collection.name}" if repository.nil?
    rescue => e
      error("Solr Worker", e.message)
      error("Solr Worker", e.backtrace)
      return
    end

    rdf_uri = RDF::URI.new(fed_item.uri)
    basic_results = repository.query(:subject => rdf_uri)
    extras = {MetadataHelper::TYPE => [], MetadataHelper::EXTENT => [], "date_group_facet" => []}
    internalUseData = {:documents_path => []}

    # Get date group if there is one
    date_result = repository.query(:subject => rdf_uri, :predicate => MetadataHelper::CREATED)
    unless date_result.empty?
      date = date_result.first_object
      group = date_group(date)
      extras["date_group_facet"] << group unless group.nil?
    end

    # get full text from item
    begin
      unless fed_item.nil? || fed_item.primary_text_path.nil?
        file = File.open(fed_item.primary_text_path)
        full_text = file.read
        file.close
      end 
    rescue
      warning("Solr_Worker", "caught exception fetching full_text for: #{object}")
      full_text = ""
    end

    # Get document info
    document_results = repository.query(:subject => rdf_uri, :predicate => RDF::URI.new(MetadataHelper::DOCUMENT))

    document_results.each { |result|
      document = result.to_hash[:object]

      doc_info = repository.query(:subject => document).to_hash[document]

      extras[MetadataHelper::TYPE] << doc_info[MetadataHelper::TYPE][0].to_s unless doc_info[MetadataHelper::TYPE].nil?

      extras[MetadataHelper::EXTENT] << doc_info[MetadataHelper::EXTENT][0].to_s unless doc_info[MetadataHelper::EXTENT].nil?

      internalUseData[:documents_path] << doc_info[MetadataHelper::SOURCE][0].to_s unless doc_info[MetadataHelper::SOURCE].nil?
    }

    store_results(object, basic_results, full_text, extras, internalUseData, collection)
  end

  #
  # Add a field to the solr document we're building. Knows about the
  # difference between dynamic and non-dynamic fields.
  #
  def add_field(result, field, value, binding)
    if @@configured_fields.include?(field)
      debug("Solr_Worker", "Adding configured field #{field} with value #{value}")
      ::Solrizer::Extractor.insert_solr_field_value(result, field, value)
    else
      debug("Solr_Worker", "Adding dynamic field #{field} with value #{value}")
      Solrizer.insert_field(result, field, value, :facetable, :stored_searchable)
    end

    process_field_mapping(field, binding)
  end

  #
  # Make a Solr document from information extracted from the Item
  #
  def make_solr_document(object, results, full_text, extras, internalUseData, collection)
    document = {}
    configured_fields_found = Set.new
    ident_parts = {collection: "Unknown Collection", identifier: "Unknown Identifier"}

    results.each { |binding|

      binding = binding.to_hash
      # Set the defaults for field and value
      field = binding[:predicate].to_s
      value = last_bit(binding[:object])

      # Now check for special cases
      if binding[:predicate] == MetadataHelper::CREATED
        value = binding[:object].to_s
      elsif binding[:predicate] == MetadataHelper::IS_PART_OF
        is_part_of = find_collection(binding[:object])
        unless is_part_of.nil?
          # This is pointing at a collection, so treat it differently
          field = MetadataHelper::COLLECTION
          value = is_part_of.name
          ident_parts[:collection] = value
        end
      elsif binding[:predicate] == MetadataHelper::IDENTIFIER
        ident_parts[:identifier] = value
      elsif @@configured_fields.include?(MetadataHelper::short_form(field)+"_facet")
        field = MetadataHelper::short_form(field)+"_facet"
      end


      # When retrieving the information for a document, the RDF::Query library is forcing
      # the text to be encoding to UTF-8, but that produces that some characters get misinterpreted,
      # so we need to correct that by re mapping the wrong characters in the right ones.
      # (maybe this is not the best solution :( )
      value_encoded = value.inspect[(1..-2)]
      replacements = []
      replacements << ['â\u0080\u0098', '‘']
      replacements << ['â\u0080\u0099', '’']
      replacements.each{ |set| value_encoded.gsub!(set[0], set[1]) }

      # Map the field name to it's short form
      field = MetadataHelper::short_form(field)
      configured_fields_found.add(field) if @@configured_fields.include?(field)
      add_field(document, field, value_encoded, binding)

    }
    unless extras.nil?
      extras.keys.each { |key|
        field = MetadataHelper::short_form(key)
        values = extras[key]
        configured_fields_found.add(field) if @@configured_fields.include?(field) && (values.size > 0)
        values.each { |value|
          add_field(document, field, value, nil)

          # creates the field mapping
          uri = RDF::URI.new(key)
          rdf_field_name = (uri.qname.present?)? uri.qname.join(':') : nil
          solr_name = (@@configured_fields.include?(field)) ? field : "#{field}_tesim"

          if ItemMetadataFieldNameMapping.create_or_update_field_mapping(solr_name, rdf_field_name, format_key(field))
            debug("Solr_Worker", "Creating new mapping for field #{field}")
          else
            debug("Solr_Worker", "Updating mapping for field: #{field}")
          end

        }
      }
    end
    unless full_text.nil?
      logger.debug "\tAdding configured field #{:full_text} with value #{trim(full_text, 128)}"
      ::Solrizer::Extractor.insert_solr_field_value(document, :full_text, full_text)
    end
    default_il = ['0']
    #debug("Solr_Worker", "Adding configured field #{:item_lists} with value #{default_il}")
    #::Solrizer::Extractor.insert_solr_field_value(document, :item_lists, default_il)
    debug("Solr_Worker", "Adding configured field #{:id} with value #{object}")
    ::Solrizer::Extractor.insert_solr_field_value(document, :id, object)
    ident = ident_parts[:collection] + ":" + ident_parts[:identifier]
    debug("Solr_Worker", "Adding configured field #{:handle} with value #{ident}")
    ::Solrizer::Extractor.insert_solr_field_value(document, :handle, ident)

    #Create group permission fields
    debug("Solr_Worker", "Adding discover Permission field for group with value #{ident_parts[:collection]}-discover")
    ::Solrizer::Extractor.insert_solr_field_value(document, :'discover_access_group_ssim', "#{ident_parts[:collection]}-discover")
    debug("Solr_Worker", "Adding read Permission field for group with value #{ident_parts[:collection]}-read")
    ::Solrizer::Extractor.insert_solr_field_value(document, :'read_access_group_ssim', "#{ident_parts[:collection]}-read")
    debug("Solr_Worker", "Adding edit Permission field for group with value #{ident_parts[:collection]}-edit")
    ::Solrizer::Extractor.insert_solr_field_value(document, :'edit_access_group_ssim', "#{ident_parts[:collection]}-edit")
    #Create user permission fields
    data_owner = collection.owner.email
    if data_owner
      debug("Solr_Worker", "Adding discover Permission field for user with value #{data_owner}-discover")
      ::Solrizer::Extractor.insert_solr_field_value(document, :'discover_access_person_ssim', "#{data_owner}")
      debug("Solr_Worker", "Adding read Permission field for user with value #{ident_parts[:collection]}-read")
      ::Solrizer::Extractor.insert_solr_field_value(document, :'read_access_person_ssim', "#{data_owner}")
      debug("Solr_Worker", "Adding edit Permission field for user with value #{ident_parts[:collection]}-edit")
      ::Solrizer::Extractor.insert_solr_field_value(document, :'edit_access_person_ssim', "#{data_owner}")
    end

    # Add in defaults for the configured fields we haven't found so far
    @@configured_fields.each { |field|
      add_field(document, field, "unspecified", nil) unless configured_fields_found.include?(field)
    }

    add_json_metadata_field(document, internalUseData)

    return document
  end

  #
  #
  #
  def add_json_metadata_field(document, internalUseData)
    itemInfo = create_display_info_hash(document)
    # Removes id, item_list, *_ssim and *_sim fields
    #metadata = itemInfo.metadata.delete_if {|key, value| key.to_s.match(/^(.*_sim|.*_ssim|item_lists|id)$/)}
    metadata = itemInfo.metadata.delete_if {|key, value| key.to_s.match(/^(.*_sim|.*_ssim|id)$/)}

    # create a mapping with the documents locations {filename => fullPath}
    documentsLocations = {}
    #documentsPath = Hash[*document.select{|key, value| key.to_s.match(/#{MetadataHelper.short_form(MetadataHelper::SOURCE.to_s)}_.*/)}.first]
    documentsPath = internalUseData[:documents_path]

    if (documentsPath.present?)
      documentsPath.each do |path|
        documentsLocations[File.basename(path).to_s] = path.to_s
      end
    end

    jsonMetadata = {catalog_url:itemInfo.catalog_url,
            metadata:metadata,
            primary_text_url:itemInfo.primary_text_url,
            annotations_url:itemInfo.annotations_url,
            documents: itemInfo.documents,
            documentsLocations: documentsLocations}.to_json

    ::Solrizer::Extractor.insert_solr_field_value(document, 'json_metadata', jsonMetadata.to_s)

  end


  #---------------------------------------------------------------------------------------------------
  def process_field_mapping(field, binding)
    rdf_field_name = nil
    if binding.present? and binding[:predicate].qname.present?
      rdf_field_name = binding[:predicate].qname.join(':')
    elsif binding.present?
      debug("Solr_Worker", "WARNING: Vocab not defined for field #{field} (#{binding[:predicate].to_s}). Please update it in /lib/rdf/vocab.")
    end

    solr_name = (@@configured_fields.include?(field)) ? field : "#{field}_tesim"

    if ItemMetadataFieldNameMapping.create_or_update_field_mapping(solr_name, rdf_field_name, format_key(field))
      debug("Solr_Worker", "Creating new mapping for field #{solr_name}")
    else
      debug("Solr_Worker", "Updating mapping for field: #{solr_name}")
    end

  end

  def format_key(uri)
    uri = last_bit(uri).sub(/_tesim$/, '')
    uri = uri.sub(/_facet/, '')
    uri = uri.sub(/^([A-Z]+_)+/, '') unless uri.starts_with?('RDF')

    uri
  end

  #---------------------------------------------------------------------------------------------------

  #
  # Make a Solr update document from information extracted from the Item
  #
  def make_solr_update(document)

    #add_attributes = {:allowDups => false, :commitWithin => 10}
    #
    #xml_update = @@solr.xml.add(document, add_attributes) do | doc |
    #  document.keys.each do | key |
    #    if (key.to_s != 'id')
    #      doc.field_by_name(key).attrs[:update] = 'set'
    #    end
    #  end
    #end

    xml_update = "";
    xml_update << "<add overwrite='true' allowDups='false'> <doc>"
      
    document.keys.each do | key |
    
      value = document[key]

      if key.to_s == "id"
        xml_update << "<field name='#{key.to_s}'>#{value.to_s}</field>"
      else
        if value.kind_of?(Array)
          value.each do |val| 
            xml_update << "<field name='#{key.to_s}' update='set'>#{CGI.escapeHTML(val.to_s.force_encoding('UTF-8'))}</field>"
          end
        else
          xml_update << "<field name='#{key.to_s}' update='set'>#{CGI.escapeHTML(value.to_s.force_encoding('UTF-8'))}</field>"
        end
      end
    end
    
    xml_update << "</doc> </add>"

    debug("Solr_Worker", "XML= " + xml_update)
    
    xml_update

  end

  #
  # Search for an object in Solr to see if we need to add or update
  #
  def object_exists_in_solr?(object)
    response = @@solr.get 'select', :params => { :q => object }
    (response['response']['docs'].count > 0) ? true : false
  end

  #
  # Update Solr with the information we've found
  #
  def store_results(object, results, full_text, extras = nil, internalUseData, collection)
    get_solr_connection
    document = make_solr_document(object, results, full_text, extras, internalUseData, collection)
    if object_exists_in_solr?(object)
      debug("Solr_Worker", "Updating " + object.to_s)
      xml_update = make_solr_update(document)
      response = @@solr.update :data => xml_update
      debug("Solr_Worker", "Update response= #{response.to_s}")
      response = @@solr.commit
      debug("Solr_Worker", "Commit response= #{response.to_s}")
    else
      debug("Solr_Worker", "Inserting " + object.to_s )
      response = @@solr.add(document)
      response = @@solr.commit
    end
  end

  #
  # End of Indexing
  # -----------------------------------------------------------------------------
  #


  #
  # =============================================================================
  # Deleting
  # =============================================================================
  #

  #
  # Invoked when we get the "delete" command.
  #
  def delete(object)
    get_solr_connection
    @@solr.delete_by_id(object)
    @@solr.commit
  end

  #
  # End of Deleting
  # -----------------------------------------------------------------------------
  #


  #
  # =============================================================================
  # Solr
  # =============================================================================
  #

  #
  # Class variables for information about Solr
  @@solr_config = nil
  @@solr = nil

  #
  # Initialise the connection to Solr
  #
  def get_solr_connection
    if @@solr_config.nil?
      @@solr_config = Blacklight.solr_config
      @@solr        = RSolr.connect(@@solr_config)
    end
  end

  #
  # End of Solr
  # -----------------------------------------------------------------------------
  #



  #
  # =============================================================================
  # Date Handling
  # =============================================================================
  #
  def output(string)
    logger.debug(string)
  end

  def year_matching_regexp(string, regexp, match_idx)
    match = regexp.match(string)
    match = match[match_idx] unless match.nil?
    return match
  end

  def year_from_integer(y)
    y = y + 1900 if y < 100   # Y2K hack all over again?
    return y
  end


  #
  # Build a regular expression which looks for ^f1/f2/f3$ and records each element.
  # The separator doesn't have to be a /, any non-digit will do (but we insist on
  # the two separators being the same).
  #
  def make_regexp(f1, f2, f3)
    string = '^('
    string += f1
    string += ')(\D)('
    string += f2
    string += ')\2('
    string += f3
    string += ')$'
    return Regexp.new(string)
  end


  #
  # Try (quite laboriously) to get a year from the given date string.
  # Do this by matching against various regular expressions, which
  # correspond to various date formats.
  #
  def year_from_string(string)
    string = string.gsub('?', '') # Remove all doubt...
    day_p   = '1|2|3|4|5|6|7|8|9|01|02|03|04|05|06|07|08|09|10|11|12|13|14|15|16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31'
    month_p = '1|2|3|4|5|6|7|8|9|01|02|03|04|05|06|07|08|09|10|11|12'
    year_p  = '[12]\d\d\d|\d\d'
    year ||= year_matching_regexp(string, make_regexp(day_p, month_p, year_p), 4)                 # 99/99/99 UK/Aus stylee
    year ||= year_matching_regexp(string, make_regexp(month_p, day_p, year_p), 4)                 # 99/99/99 US stylee
    year ||= year_matching_regexp(string, make_regexp(year_p, month_p, day_p), 1)                 # 99/99/99 Japan stylee

    year ||= year_matching_regexp(string, /^(\d+)$/, 1)                                           # 9999
    year ||= year_matching_regexp(string, /^\d+(\s)[[:alpha:]]+\1(\d+)/, 2)                       # 99 AAAAA 99
    year ||= year_matching_regexp(string, /^(\d{4})-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\+\d{4})?/, 1)  # ISO
    year ||= year_matching_regexp(string, /(\d+)$/, 1)  # Getting desperate, so look for digits at the end of the string
    unless year == nil
      year = year_from_integer(year.to_i)
    end
    return year
  end


  #
  # In order to handle the faceted search of date fields, we group them into
  # decades.
  #
  def date_group(field, resolution=10)
    #
    # Work out the date which field represents, whether it's a String or
    # an Integer or some other hideous mess.
    #
    c = field.class

    case
      when c == String
        year = year_from_string(field)
      when c == Fixnum
        year = year_from_integer(field)
      else
        year = year_from_string(field.to_s)
    end

    return "Unknown" if year.nil?

    #
    # Now work out the group into which it should fall and return a String
    # denoting that.
    #
    year /= resolution
    first = year * resolution
    last  = first + resolution - 1
    return "#{first} - #{last}"
  end

  #
  # End of Date Handling
  # -----------------------------------------------------------------------------
  #


  #
  # =============================================================================
  # Utility methods
  # =============================================================================
  #

  #
  # Look for a collection which the given URI might indicate. If we find one,
  # return it, otherwise return nil.
  #
  def find_collection(uri)
    uri = uri.to_s
    c = Collection.find_by_uri(uri)
    c = Collection.find_by_name(last_bit(uri)) if c.nil?
    c
  end


  #
  # Extract the last part of a path/URI/slash-separated-list-of-things
  #
  def last_bit(uri)
    str = uri.to_s                # just in case it is not a String object
    return str if str.match(/\s/) # If there are spaces, then it's not a path(?)
    return str.split('/')[-1]
  end


  #
  # Print out the results of an RDF query
  #
  def print_results(results, label)
    debug("Solr_Worker", "Results #{label}, with #{results.count} solutions(s)")
    results.each { |result|
      result.each_binding { |name, value|
        debug("Solr_Worker", "> #{name} -> #{value} (#{value.class})")
      }
    }
  end

  #
  # Trim a string to no more than the given number of characters
  #
  def trim(string, num)
    return string if string.length <= num
    return string[0, num-3] + "..."
  end

  #
  # End of Utility methods
  # -----------------------------------------------------------------------------
  #
end
