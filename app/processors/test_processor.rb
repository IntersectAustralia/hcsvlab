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
    x = XMLHelper.new(message)
    logger.debug "TestProcessor received message, title: #{x.title}, content: #{x.content}, summary: #{x.summary}"

    if x.rels_ext?
      symbol = :relsExt
    elsif x.desc_metadata?
      symbol = :descMetadata
    else
      symbol = nil
    end
      
    if !symbol.nil?
      if ! @@cache.has_key?(x.summary)
        @@cache[x.summary] = {}
      end

      @@cache[x.summary][symbol] = true
      
      if @@cache[x.summary].size == 2
        send_message(x.summary) 
      end
    end
  end

  def send_message(objectID)
    logger.debug "TestProcessor sending instruction to solr_worker: index #{objectID}"
    publish :solr_worker, "index #{objectID}"
    @@cache.delete(objectID)
  end

end
