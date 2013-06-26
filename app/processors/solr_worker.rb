require 'linkeddata'
require 'xmlsimple'

#
# Helper class for interpreting the RELS-EXT we get from the Fedora message
# queues. Currently a naive implementation based on regexp matching.
#
# Create a new RDFHelper from a String representation of the RELS-EXT RDF (as
# obtained from Fedora) and the new object will put the hasModel resource into
# its :type attribute. This should be "blah-blah-Item" or "blah-blah-Document"
#
class RDFHelper

  attr_accessor :xml, :type

  def initialize(xmlString)
    @xml  = xmlString
    @type = extract(generate_regexp('hasModel', 'resource'))
  end

private

  def generate_regexp(tag, sub)
    # We assume we're looking for either:
    #   <ns0:#{tag} rdf:#{sub}="blah-blah-blah"></ns0:#{tag}>
    # and we extract the "blah-blah-blah" part. We also allow any number in
    # the namespace name, not just zero
    return /<ns\d+:#{tag} rdf:#{sub}="([^"]*)"><\/ns\d+:#{tag}>/
  end

  def extract(regexp)
    # Look for the regular expression in the RDF, and if we find it return the
    # aforementioned "blah-blah-blah" part. If we don't find it, return nil.
    match = regexp.match(xml)
    return match[1] unless match == nil
    return nil
  end
end


#
# Solr_Worker
#
class Solr_Worker < ApplicationProcessor

  FEDORA_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/fedora.yml")[Rails.env] unless const_defined?(:FEDORA_CONFIG)

  @@configured_fields = Set.new([
    'DC_is_part_of',
    'date_group',
    'AUSNC_mode',                 
    'AUSNC_speech_style',         
    'AUSNC_interactivity',        
    'AUSNC_communication_context',
    'AUSNC_audience',           
    'OLAC_discourse_type',       
    'OLAC_language',              
    'DC_type'                    
  ])

  subscribes_to :solr_worker

  def on_message(message)
    # Expect message to be a command verb followed by the name of a Fedora object
    # and then do what the verb says to the object. Complain if the message is
    # badly formed, or we don't understand the command verb.
    
    logger.debug "Solr_Worker received: " + message
    parse = message.split(' ')

    if parse.size != 2
       logger.debug "\tbadly formatted instruction, expecting 'command object'"
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
      logger.debug "\tunknown instruction: #{command}"
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
    uri = buildURI(object, 'descMetadata')
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
      extras = {MetadataHelper::TYPE => [], MetadataHelper::EXTENT => [], "date_group" => []}
      full_text = nil

      # Look for any fields which we're going to group in the indexing.
      # At the moment this is solely the Date field.
      query = RDF::Query.new({item => {MetadataHelper::CREATED => :date}})
      results = query.execute(graph)
      results.each { |result|
        date = result[:date]
        group = date_group(date)
        extras["date_group"] << group unless group.nil?
      }

      # Get the full text, if there is any
      fed_item = Item.find(object)
      unless fed_item.nil? || fed_item.primary_text.nil?
        full_text = fed_item.primary_text.content
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
  # difference between dynamic and non-dynamic fields, and it maps the
  # field name to the shortened form.
  #
  def add_field(result, field, value)
    field = MetadataHelper::short_form(field)
    if @@configured_fields.include?(field)
      logger.debug "\tAdding configured field #{field} with value #{value}"
      ::Solrizer::Extractor.insert_solr_field_value(result, field, value)
    else
      logger.debug "\tAdding dynamic field #{field} with value #{value}"
      Solrizer.insert_field(result, field, value, :facetable, :stored_searchable)
    end
  end

  #
  # Make a Solr document from information extracted from the Item
  #
  def make_solr_document(object, results, full_text, extras)
    result = {}

    results.each { |binding| 
      if binding[:predicate] == MetadataHelper::CREATED
        field = binding[:predicate].to_s
        value = binding[:object].to_s
      else
        field = binding[:predicate].to_s
        value = last_bit(binding[:object])
      end
      add_field(result, field, value)
    }
    unless extras.nil?
      extras.keys.each { |key|
        values = extras[key]
        values.each { |value|
          add_field(result, key, value)
        }
      }
    end
    unless full_text.nil?
      logger.debug "\tAdding configured field #{:full_text} with value #{trim(full_text, 128)}"
      ::Solrizer::Extractor.insert_solr_field_value(result, :full_text, full_text)
    end
    default_il = ['0']
    logger.debug "\tAdding configured field #{:item_lists} with value #{default_il}"
    ::Solrizer::Extractor.insert_solr_field_value(result, :item_lists, default_il)
    logger.debug "\tAdding configured field #{:id} with value #{object}"
    ::Solrizer::Extractor.insert_solr_field_value(result, :id, object)

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
    xml_update << "<add><doc>"
  
    document.keys.each do | key |
    
      value = document[key]
    
      if (key.to_s == "id")
        xml_update << "<field name='#{key.to_s}'>#{CGI.escapeHTML(value.to_s.force_encoding('UTF-8'))}</field>"
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
    
    xml_update << "</doc></add>"

    logger.debug "XML= " + xml_update
    
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
      logger.debug "Updating " + object.to_s
      xml_update = make_solr_update(document)
      @@solr.update :data => xml_update
    else
      logger.debug "Inserting " + object.to_s 
      @@solr.add(document)
    end
    @@solr.commit
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
  # Extract the last part of a path/URI/slash-separated-list-of-things
  #
  def last_bit(uri)
    str = uri.to_s   # just in case it is not a String object
    return str.split('/')[-1]
  end


  #
  # Print out the results of an RDF query
  #
  def print_results(results, label)
    logger.debug("Results #{label}, with #{results.count} solutions(s)")
    results.each { |result|
      result.each_binding { |name, value|
        logger.debug("> #{name} -> #{value} (#{value.class})")
      }
      logger.debug("")
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
