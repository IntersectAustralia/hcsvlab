<<<<<<< HEAD
#
# Helper class for interpreting the XML we get from the Fedora message queues.
# Naive implementation based on regexp matching.
#
class XMLHelper

  attr_accessor :xml, :title, :content, :summary

  def initialize(xmlString)
    @xml = xmlString
    @title = extract(genRE('title'))
    @content = extract(genRE('content'))
    @summary = extract(genRE('summary'))
  end

  def rels_ext?
    return content == "RELS-EXT"
  end

  def desc_metadata?
    return content == "descMetadata"
  end

private

  def genRE(tag)
    return /<#{tag} type="text">([\w\-\:]+)<\/#{tag}>/
  end

  def extract(regexp)
    match = regexp.match(xml)
    return match[1] unless match == nil
    return nil
  end
end

#
# Basic processor for incoming messages from Fedora
#
class TestProcessor < ApplicationProcessor

  subscribes_to :fedora_update
#  subscribes_to :fedora_access

  @@cache = {}
 
  def on_message(message)
#    logger.debug "TestProcessor received: " + message
    x = XMLHelper.new(message)
    logger.debug "TestProcessor received message, title: #{x.title}, content: #{x.content}, summary: #{x.summary}"

    #
    # Make sure the cache has an entry for this object
    #
    if ! @@cache.has_key?(x.summary)
      @@cache[x.summary] = {}
      logger.debug "\tFirst mention of #{x.summary}"
    end

    if x.rels_ext?
      @@cache[x.summary][:relsExt] = true
      logger.debug "\tcache[#{x.summary}] = #{@@cache[x.summary]}"
    end
      
    if x.desc_metadata?
      @@cache[x.summary][:descMetadata] = true
      logger.debug "\tcache[#{x.summary}] = #{@@cache[x.summary]}"
    end
     
    if @@cache[x.summary].size == 2
      send_message(x.summary) 
    end
  end

  def send_message(objectID)
    logger.debug "TestProcessor sending message to index #{objectID}"
    publish :solr_worker, "index #{objectID}"
    @@cache.delete(objectID)
  end

end
