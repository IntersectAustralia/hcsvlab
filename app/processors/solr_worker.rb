require 'linkeddata'
require 'xmlsimple'


#
# Constants for AUSNC
#
class AUSNC
  
private
  BASE_URI = 'http://ns.ausnc.org.au/schemas/ausnc_md_model/' unless const_defined?(:BASE_URI)

public
  AUDIENCE              = RDF::URI(BASE_URI + 'audience') unless const_defined?(:AUDIENCE)
  COMMUNICATION_CONTEXT = RDF::URI(BASE_URI + 'communication_context') unless const_defined?(:COMMUNICATION_CONTEXT)
  INTERACTIVITY         = RDF::URI(BASE_URI + 'interactivity') unless const_defined?(:INTERACTIVITY)
  MODE                  = RDF::URI(BASE_URI + 'mode') unless const_defined?(:MODE)
  SPEECH_STYLE          = RDF::URI(BASE_URI + 'speech_style') unless const_defined?(:SPEECH_STYLE)
  DOCUMENT              = RDF::URI(BASE_URI + 'document') unless const_defined?(:DOCUMENT)

end


#
# Constants for OLAC
#
class OLAC

private
  BASE_URI = 'http://www.language-archives.org/OLAC/1.1/' unless const_defined?(:BASE_URI)

public  
  DISCOURSE_TYPE = RDF::URI(BASE_URI + 'discourse_type') unless const_defined?(:DISCOURSE_TYPE)
  LANGUAGE       = RDF::URI(BASE_URI + 'language') unless const_defined?(:LANGUAGE)

end


#
# Constants for PURL
#
class PURL

private
  BASE_URI = 'http://purl.org/dc/terms/' unless const_defined?(:BASE_URI)

public  
  IS_PART_OF = RDF::URI(BASE_URI + 'isPartOf') unless const_defined?(:IS_PART_OF)
  TYPE       = RDF::URI(BASE_URI + 'type') unless const_defined?(:TYPE)
  EXTENT     = RDF::URI(BASE_URI + 'extent') unless const_defined?(:EXTENT)
  CREATED    = RDF::URI(BASE_URI + 'created') unless const_defined?(:CREATED)
  IDENTIFIER = RDF::URI(BASE_URI + 'identifier') unless const_defined?(:IDENTIFIER)
  SOURCE     = RDF::URI(BASE_URI + 'source') unless const_defined?(:SOURCE)
  TITLE      = RDF::URI(BASE_URI + 'title') unless const_defined?(:TITLE)
  TYPE       = RDF::URI(BASE_URI + 'type') unless const_defined?(:TYPE)

end


#
# Constants for DC
#
class DC

private
  BASE_URI = 'http://purl.org/dc/elements/1.1/' unless const_defined?(:BASE_URI)

public  
  TITLE = RDF::URI(BASE_URI + 'title') unless const_defined?(:TITLE)

end


#
# Constants for FEDORA
#
class FEDORA

private
  BASE_URI = 'info:fedora/fedora-system:def/relations-external#' unless const_defined?(:BASE_URI)

public  
  IS_MEMBER_OF = RDF::URI(BASE_URI + 'isMemberOf') unless const_defined?(:IS_MEMBER_OF)

end


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
    # We assume we're looking foreither:
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
    query = RDF::Query.new({:description => {FEDORA::IS_MEMBER_OF => :is_member_of}})
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
    query = RDF::Query.new({:item => {PURL::IS_PART_OF => :corpus}})
    results = query.execute(graph)

    unless results.size == 0
      # Now find all the triplets which have the Item as the subject
      # and add them all to the index
      item = results[0][:item]
      query = RDF::Query.new({item => {:predicate => :object}})
      basic_results = query.execute(graph)
      print_results(basic_results, "bloody hell")

      # Now we have the basic results, we have a guddle about for any
      # extra information in which we're interested. Start by creating 
      # the Hash into which we will accumulate this extra data.
      extras = {PURL::TYPE => [], PURL::EXTENT => [], "date_group" => []}

      # Look for any fields which we're going to group in the indexing.
      # At the moment this is solely the Date field.
      query = RDF::Query.new({item => {PURL::CREATED => :date}})
      results = query.execute(graph)
      results.each { |result|
        date = result[:date]
        group = date_group(date)
        extras["date_group"] << group unless group.nil?
      }


      # Finally look for references to Documents within the metadata and
      # find their types and extents.
      query = RDF::Query.new({item => {AUSNC::DOCUMENT => :document}})
      results = query.execute(graph)

      results.each { |result|
        document = result[:document]
        type_query   = RDF::Query.new({document => {PURL::TYPE => :type}})
        extent_query = RDF::Query.new({document => {PURL::EXTENT => :extent}})

        inner_results = type_query.execute(graph)
        unless inner_results.size == 0
          inner_results.each { |inner_result|
            extras[PURL::TYPE] << inner_result[:type].to_s
          }
        end

        inner_results = extent_query.execute(graph)
        unless inner_results.size == 0
          inner_results.each { |inner_result|
            extras[PURL::EXTENT] << inner_result[:extent].to_s
          }
        end
      }

      store_results(object, basic_results, extras)
    end
  end

  #
  # Set the parent/child relationship for the document.
  #
  def link_document(document_id, item_id)
    # Get the two objects
    do_it = true   # until proven otherwise

    begin
      item = Item.find(item_id)
    rescue ActiveFedora::ObjectNotFoundError
      logger.warning "Cannot find parent Item with id #{item_id}"
      do_it = false
    end

    begin
      document = Document.find(document_id)
    rescue ActiveFedora::ObjectNotFoundError
      logger.warning "Cannot find Document with id #{document_id}"
      do_it = false
    end

    return unless do_it

    # We now have both the Item and the Document, so link them together
    # and save the modified versions
    logger.debug "Setting #{item_id} as the Item for Document #{document_id}"
    document.item = item
    document.save

  end

  #
  # Invoked when we get the "index" command. Determine the type of object it is
  # and item it accordingly.
  #
  def index(object)
    parent = parent_object(object)
    if parent.nil?
      index_item(object)
    else
  #    link_document(object, parent)
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
  # Build a description of the fields to index.
  #
  def interesting_fields
    # TODO: read from a config file
    return {
      AUSNC::MODE                  => :mode,
      AUSNC::SPEECH_STYLE          => :speech_style,
      AUSNC::INTERACTIVITY         => :interactivity,
      AUSNC::COMMUNICATION_CONTEXT => :communication_context,
      AUSNC::AUDIENCE              => :audience,
      OLAC::DISCOURSE_TYPE         => :discourse_type,
      PURL::IS_PART_OF             => :is_part_of
    }
  end

  #
  # Make a Solr document from information extracted from the Item
  #
  def make_solr_document(object, results, extras)
    result = {}

    results.each { |binding| 
      if binding[:predicate] == PURL::CREATED
        field = binding[:predicate].to_s
        value = binding[:object].to_s
      else
        field = binding[:predicate].to_s
        value = last_bit(binding[:object])
      end
      logger.debug "\tAdding field #{field} with value #{value} (#{value.class})"
      Solrizer.insert_field(result, field, value, :facetable, :stored_searchable)
    }
    unless extras.nil?
      extras.keys.each { |key|
        values = extras[key]
        values.each { |value|
          logger.debug "\tAdding field #{key} with value #{value} (#{value.class})"
          Solrizer.insert_field(result, key, value, :facetable, :stored_searchable)
        }
      }
    end
    logger.debug "\tAdding index #{:id} with value #{object}"
    ::Solrizer::Extractor.insert_solr_field_value(result, :id, object)

    return result
  end

  #
  # Update Solr with the information we've found
  #
  def store_results(object, results, extras = nil)
    get_solr_connection()
    document = make_solr_document(object, results, extras)
    @@solr.add(document)
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
  # End of Utility methods
  # -----------------------------------------------------------------------------
  #

end
