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
    # Expect message to me a command verb followed by the name of a Fedora object
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
  # Do the indexing for a Document
  #
  def index_document(object, item)
    # Find the title of the Document from its Dublin Core datastream
    uri = URI(buildURI(object, 'DC'))
    dc_xml = XmlSimple.xml_in(uri.open)
    title = dc_xml["title"][0]
    title = RDF::URI(title)

    # Now get the descMetadata for the Document (as this is the same as the
    # Item's metadata, we need to do some guddling about to find the info
    # we want, so start by getting the metadata.
    uri = buildURI(object, 'descMetadata')
    graph = RDF::Graph.load(uri)

    # Now find the which <document> in the metadata corresponds to the
    # Document. We do this by looking for the predicate which has the
    # Document's URI as the object, assuming that will be relating the
    # URI to one of the <document>s in the metadata.
    query = RDF::Query.new({:document => {:predicate => title}})
    results = query.execute(graph)

    unless results.size == 0
      # We've located one or more <documents> which link to the Document,
      # in time-honoured tradition, we arbitrarily pick the first one.
      # Now find all the triplets which have that first <document> as 
      # their subject and add them to the index.
      document = results[0][:document]
      query = RDF::Query.new({document => {:predicate => :object}})
      results = query.execute(graph)
      store_results(object, results, {'Item' => [item]})
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
    else
      # index_document(object, parent)
      logger.debug "Not indexing the Document #{object}"
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
      field = binding[:predicate].to_s
      value = last_bit(binding[:object])
      logger.debug "\tAdding field #{field} with value #{value}"
      Solrizer.insert_field(result, field, value, :facetable, :stored_searchable)
    }
    unless extras.nil?
      extras.keys.each { |key|
        values = extras[key]
        values.each { |value|
          logger.debug "\tAdding field #{key} with value #{value}"
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

  def date_from_integer(y)
    logger.debug "Trying to resolve integer #{y} into a Date"
    y = y + 1900 if y < 100   # Y2K hack all over again?
    date = Date.new(y)
    return date
  end


  def date_from_string(string)
    date = nil
    begin
      logger.debug "Trying to resolve string #{string} into a Date"
      date = Date.parse(string)
    rescue
      logger.debug "OK, Trying to convert string #{string} into an Integer then a Date"
      begin
        y = string.to_i
        date = date_from_integer(y)
      rescue
      end
    end
    return date
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

    logger.debug "resolving #{c.to_s} date #{field} as a date"

    case
      when c == String
        date = date_from_string(field)
      when c == Fixnum
        date = date_from_integer(field)
      else
        date = date_from_string(field.to_s)
    end

    return nil if date.nil?
    
    #
    # Now work out the group into which it should fall and return a String
    # denoting that.
    #
    y = date.year
    y /= resolution
    first = y * resolution
    last  = first + resolution - 1
    logger.debug "Range is #{first} - #{last}"
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
        logger.debug("> #{name} -> #{value}")
      }
      logger.debug("")
    }
  end

  #
  # End of Utility methods
  # -----------------------------------------------------------------------------
  #

end
