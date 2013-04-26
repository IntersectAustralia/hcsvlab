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

end


#
# Constants for OLAC
#
module OLAC

private
  BASE_URI = 'http://www.language-archives.org/OLAC/1.1/'

public  
  DISCOURSE_TYPE = RDF::URI(BASE_URI + 'discourse_type')

end


#
# Constants for PURL
#
module PURL

private
  BASE_URI = 'http://purl.org/dc/terms/'

public  
  IS_PART_OF = RDF::URI(BASE_URI + 'isPartOf')

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
  # Determine if the Fedora object is something we should be indexing or not, based on
  # what its RELS-EXT tells us about whether it's a Document (no) or an Item (yes).
  #
  def shouldIndex?(object)
    uri = buildURI(object, 'RELS-EXT')
    rdf = nil

    open(uri) { |f| rdf = f.string }
    x = RDFHelper.new(rdf)
    return x.type =~ /Item$/
  end

  #
  # Do the actual indexing
  #
  def actuallyIndex(object)
    uri = buildURI(object, 'descMetadata')
    graph = RDF::Graph.load(uri)
    fields = interesting_fields()
    results = query_graph(graph, fields)
    store_results(object, results)
  end

  #
  # Invoked when we get the "index" command. Not everything should be indexed, so
  # check if the object should be, and do it if appropriate.
  #
  def index(object)
    if shouldIndex?(object)
      actuallyIndex(object)
    else
      logger.debug "\t#{object} is not an Item, not indexing"
    end
  end

  #
  # Build the URL of a particular datastream of the given Fedora object
  #
  def buildURI(object, datastream)
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
        result[key] = individual_result[0][value]
      end
    }

    return result
  end

  #
  # Build a description of the fields to index.
  #
  def interesting_fields
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
  # Make a Solr document from information extracted from theItem
  #
  def make_solr_document(object, results)
    result = {}

    results.keys.each { |field| 
      logger.debug "\tAddng field #{field.to_s} with value #{results[field]}"
      Solrizer.insert_field(result, field.to_s, results[field], :facetable)
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

end
