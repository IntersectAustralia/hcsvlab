require 'rdf'
require 'linkeddata'


#
# Constants for AUSNC
#
class AUSNC
  
private
  BASE_URI = 'http://ns.ausnc.org.au/schemas/ausnc_md_model/'

public
  AUDIENCE              = RDF::URI(BASE_URI + 'audience')
  COMMUNICATION_CONTEXT = RDF::URI(BASE_URI + 'communication_context')
  INTERACTIVITY         = RDF::URI(BASE_URI + 'interactivity')
  MODE                  = RDF::URI(BASE_URI + 'mode')
  SPEECH_STYLE          = RDF::URI(BASE_URI + 'speech_style')

  def stripped()
    str = self.to_s
    return str[BASE_URI.length..str.length]
  end

end


#
# Constants for OLAC
#
class OLAC

private
  BASE_URI = 'http://www.language-archives.org/OLAC/1.1/'

public  
  DISCOURSE_TYPE = RDF::URI(BASE_URI + 'discourse_type')

  def stripped()
    str = self.to_s
    return str[BASE_URI.length..str.length]
  end

end


#
# Constants for PURL
#
class PURL

private
  BASE_URI = 'http://purl.org/dc/terms/'

public  
  IS_PART_OF = RDF::URI(BASE_URI + 'isPartOf')

  def stripped()
    str = self.to_s
    return str[BASE_URI.length..str.length]
  end

end


#
# Constants for FEDORA
#
class FEDORA

private
  BASE_URI = 'info:fedora/fedora-system:def/relations-external#'

public  
  IS_MEMBER_OF = RDF::URI(BASE_URI + 'isMemberOf')

  def stripped()
    str = self.to_s
    return str[BASE_URI.length..str.length]
  end

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
    else
      logger.debug "\tunknown instruction: #{command}"
      return
    end

  end

private

  #
  # Class variables for information about Solr
  @@solr_config = nil
  @@solr = nil

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
    query = RDF::Query.new({:document => {PURL::IS_PART_OF => :corpus}})
    results = query.execute(graph)

    unless results.size == 0
      # Now find all the triplets which have the Item as the subject
      # and add them all to the index
      document = results[0][:document]
      query = RDF::Query.new({document => {:predicate => :object}})
      results = query.execute(graph)
      store_results(object, results)
    end
  end

  #
  # Do the indexing for a Document
  #
  def index_document(object)
    logger.debug "\tIndex document #{object}"
    return nil
  end

  #
  # Invoked when we get the "index" command. Determine the type of object it is
  # and item it accordingly.
  #
  def index(object)
    if parent_object(object).nil?
      index_item(object)
    else
      index_document(object)
    end
  end

  #
  # Build the URL of a particular datastream of the given Fedora object
  #
  def buildURI(object, datastream)
    # TODO: get base URI from a config file
    return "http://localhost:8983/fedora/objects/#{object}/datastreams/#{datastream}/content"
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
  def make_solr_document(object, results)
    result = {}

    results.each { |binding| 
      field = binding[:predicate].to_s
      value = last_bit(binding[:object])
      logger.debug "\tAddng field #{field} with value #{value}"
      Solrizer.insert_field(result, field, value, :facetable)
    }
    logger.debug "\tAddng index #{:id} with value #{object}"
    ::Solrizer::Extractor.insert_solr_field_value(result, :id, object)

    return result
  end

  #
  # Update Solr with the information we've found
  #
  def store_results(object, results)
    if @@solr_config.nil?
      @@solr_config = Blacklight.solr_config
      @@solr        = RSolr.connect(@@solr_config)
    end

    document = make_solr_document(object, results)
    @@solr.add(document)
    @@solr.commit
  end


  #
  # Extract the last part of a path/URI/slash-separated-list-of-things
  #
  def last_bit(uri)
    str = uri.to_s   # just in case it is not a String object
    return str.split('/')[-1]
  end

end
