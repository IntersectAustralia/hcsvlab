require 'linkeddata'
require 'xmlsimple'

#
# Solr_Worker
#
class Solr_Worker < ApplicationProcessor

  #
  # =============================================================================
  # Configuration
  # =============================================================================
  #

  #
  # Load up the facet fields from the supplied config
  #
  def self.load_config()
    @@configured_fields = Set.new()
    FACETS_CONFIG[:facets].each do |aFacetConfig|
      @@configured_fields.add(aFacetConfig[:name])
    end
  end


  FEDORA_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/fedora.yml")[Rails.env] unless const_defined?(:FEDORA_CONFIG)
  FACETS_CONFIG = YAML.load_file(Rails.root.join("config", "facets.yml")) unless const_defined?(:FACETS_CONFIG)

  load_config()
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
      index(object)
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
  # Find the name of the Fedora object's parent object. In other words, if object
  # represents a Document, return the id of the Item of which it is a part. If it
  # is an Item, return nil. This is based on the isMemberOf field in its RELS-EXT
  # datastream.
  #
  def parent_object(object)
    uri = buildURI(object, 'RELS-EXT')
    graph = RDF::Graph.load(uri)
    query = RDF::Query.new({:description => {MetadataHelper::IS_MEMBER_OF => :is_member_of}})
    individual_result = query.execute(graph)

    return nil if individual_result.size == 0
    return last_bit(individual_result[0][:is_member_of])
  end

  #
  # Do the indexing for an Item
  #
  def index_item(object)
    uri = buildURI(object, 'rdfMetadata')
    graph = RDF::Graph.load(uri)

    # Find the identity of the Item
    query = RDF::Query.new({:item => {MetadataHelper::IS_PART_OF => :corpus}})
    results = query.execute(graph)

    unless results.size == 0
      # Now find all the triplets which have the Item as the subject
      # and add them all to the index
      item = results[0][:item]
      query = RDF::Query.new({item => {:predicate => :object}})
      basic_results = query.execute(graph)
#      print_results(basic_results, "bloody hell")

      # Now we have the basic results, we have a guddle about for any
      # extra information in which we're interested. Start by creating 
      # the Hash into which we will accumulate this extra data.
      extras = {MetadataHelper::TYPE => [], MetadataHelper::EXTENT => [], "date_group_facet" => []}
      full_text = nil

      # Look for any fields which we're going to group in the indexing.
      # At the moment this is solely the Date field.
      query = RDF::Query.new({item => {MetadataHelper::CREATED => :date}})
      results = query.execute(graph)
      results.each { |result|
        date = result[:date]
        group = date_group(date)
        extras["date_group_facet"] << group unless group.nil?
      }

      # Get the full text, if there is any
      fed_item = Item.find(object)
      begin
        unless fed_item.nil? || fed_item.primary_text.nil?
          full_text = fed_item.primary_text.content
        end 
      rescue
        warning("Solr_Worker", "caught exception fetching full_text for: #{object}")
        full_text = ""
      end

      # Finally look for references to Documents within the metadata and
      # find their types and extents.
      query = RDF::Query.new({item => {MetadataHelper::DOCUMENT => :document}})
      results = query.execute(graph)

      results.each { |result|
        document = result[:document]
        type_query   = RDF::Query.new({document => {MetadataHelper::TYPE => :type}})
        extent_query = RDF::Query.new({document => {MetadataHelper::EXTENT => :extent}})

        inner_results = type_query.execute(graph)
        unless inner_results.size == 0
          inner_results.each { |inner_result|
            extras[MetadataHelper::TYPE] << inner_result[:type].to_s
          }
        end

        inner_results = extent_query.execute(graph)
        unless inner_results.size == 0
          inner_results.each { |inner_result|
            extras[MetadataHelper::EXTENT] << inner_result[:extent].to_s
          }
        end
      }

      store_results(object, basic_results, full_text, extras)
    end
  end

  #
  # Invoked when we get the "index" command. Determine the type of object it is
  # and item it accordingly.
  #
  def index(object)
    parent = parent_object(object)
    if parent.nil?
      index_item(object)
    end
  end

  #
  # Build the URL of a particular datastream of the given Fedora object
  #
  def buildURI(object, datastream)
    return FEDORA_CONFIG["url"].to_s + "/objects/#{object}/datastreams/#{datastream}/content"
  end

  #
  # Query the given graph for each field, bearing in mind that the graph might
  # not have all of the fields
  #
  def query_graph(graph, fields)
    result = {}

    fields.keys.each { |key|
      value = fields[key]
      query = RDF::Query.new({:document => {key => value}})
      individual_result = query.execute(graph)
      unless individual_result.size == 0
        result[key] = last_bit(individual_result[0][value])
      end
    }

    return result
  end

  #
  # Add a field to the solr document we're building. Knows about the
  # difference between dynamic and non-dynamic fields.
  #
  def add_field(result, field, value)
    if @@configured_fields.include?(field)
      debug("Solr_Worker", "Adding configured field #{field} with value #{value}")
      ::Solrizer::Extractor.insert_solr_field_value(result, field, value)
    else
      debug("Solr_Worker", "Adding dynamic field #{field} with value #{value}")
      Solrizer.insert_field(result, field, value, :facetable, :stored_searchable)
    end
  end

  #
  # Make a Solr document from information extracted from the Item
  #
  def make_solr_document(object, results, full_text, extras)
    result = {}
    configured_fields_found = Set.new()
    ident_parts = {collection: "Unknown Collection", identifier: "Unknown Identifier"}

    results.each { |binding|

      # Set the defaults for field and value
      field = binding[:predicate].to_s
      value = last_bit(binding[:object])

      # Now check for special cases
      if binding[:predicate] == MetadataHelper::CREATED
        value = binding[:object].to_s
      elsif binding[:predicate] == MetadataHelper::IS_PART_OF
        # Check whether this is telling us the object is part of a collection
        collection = find_collection(binding[:object])

        unless collection.nil?
          # This is pointing at a collection, so treat it differently
          field = MetadataHelper::COLLECTION
          value = collection.short_name[0]
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
      add_field(result, field, value_encoded)
    }
    unless extras.nil?
      extras.keys.each { |key|
        field = MetadataHelper::short_form(key)
        values = extras[key]
        configured_fields_found.add(field) if @@configured_fields.include?(field) && (values.size > 0)
        values.each { |value|
          add_field(result, field, value)
        }
      }
    end
    unless full_text.nil?
      logger.debug "\tAdding configured field #{:full_text} with value #{trim(full_text, 128)}"
      ::Solrizer::Extractor.insert_solr_field_value(result, :full_text, full_text)
    end
    default_il = ['0']
    debug("Solr_Worker", "Adding configured field #{:item_lists} with value #{default_il}")
    ::Solrizer::Extractor.insert_solr_field_value(result, :item_lists, default_il)
    debug("Solr_Worker", "Adding configured field #{:id} with value #{object}")
    ::Solrizer::Extractor.insert_solr_field_value(result, :id, object)
    ident = ident_parts[:collection] + ":" + ident_parts[:identifier]
    debug("Solr_Worker", "Adding configured field #{:handle} with value #{ident}")
    ::Solrizer::Extractor.insert_solr_field_value(result, :handle, ident)

    #Create group permission fields
    debug("Solr_Worker", "Adding discover Permission field for group with value #{ident_parts[:collection]}-discover")
    ::Solrizer::Extractor.insert_solr_field_value(result, :'discover_access_group_ssim', "#{ident_parts[:collection]}-discover")
    debug("Solr_Worker", "Adding read Permission field for group with value #{ident_parts[:collection]}-read")
    ::Solrizer::Extractor.insert_solr_field_value(result, :'read_access_group_ssim', "#{ident_parts[:collection]}-read")
    debug("Solr_Worker", "Adding edit Permission field for group with value #{ident_parts[:collection]}-edit")
    ::Solrizer::Extractor.insert_solr_field_value(result, :'edit_access_group_ssim', "#{ident_parts[:collection]}-edit")
    #Create user permission fields
    data_owner = Collection.find_by_short_name(ident_parts[:collection]).first.flat_private_data_owner
    if (!data_owner.nil?)
      debug("Solr_Worker", "Adding discover Permission field for user with value #{data_owner}-discover")
      ::Solrizer::Extractor.insert_solr_field_value(result, :'discover_access_person_ssim', "#{data_owner}")
      debug("Solr_Worker", "Adding read Permission field for user with value #{ident_parts[:collection]}-read")
      ::Solrizer::Extractor.insert_solr_field_value(result, :'read_access_person_ssim', "#{data_owner}")
      debug("Solr_Worker", "Adding edit Permission field for user with value #{ident_parts[:collection]}-edit")
      ::Solrizer::Extractor.insert_solr_field_value(result, :'edit_access_person_ssim', "#{data_owner}")
    end

    # Add in defaults for the configured fields we haven't found so far
    @@configured_fields.each { |field|
      add_field(result, field, "unspecified") unless configured_fields_found.include?(field)
    }
    return result
  end

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
    
      if (key.to_s == "id")
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
    
    return xml_update

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
  def store_results(object, results, full_text, extras = nil)
    get_solr_connection()
    document = make_solr_document(object, results, full_text, extras)
    if (object_exists_in_solr?(object))
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
    get_solr_connection()
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
    c = Collection.find_by_short_name(last_bit(uri)) if c.size == 0
    if c.size == 0
      c = nil
    else
      c = c[0]
    end
    return c
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
