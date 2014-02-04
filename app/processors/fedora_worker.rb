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
    return content == "rdfMetadata"
  end

  def finished_work?
    return title == "finishedWork"
  end

  def is_document
    return title == "isDocument"
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
class FedoraWorker < ApplicationProcessor

  subscribes_to :fedora_update
#  subscribes_to :fedora_access

  @@cache = {}
 
  def on_message(message)

    x = XMLHelper.new(message)
    info("Fedora_Worker", "received message, title: #{x.title}, content: #{x.content}, summary: #{x.summary}")

    case x.title
      when "addDatastream"
        index(x)
      when "finishedWork"
        index(x)
      when "isDocument"
        remove_from_cache(x)
      when "purgeObject"
        send_solr_message("delete", x.summary)
    end
  end

  def index(xmlHelper)
    if xmlHelper.rels_ext?
      symbol = :relsExt
    elsif xmlHelper.desc_metadata?
      symbol = :rdfMetadata
    elsif xmlHelper.finished_work?
      symbol = :finishedWork
    else
      symbol = nil
    end

    if !symbol.nil?
      if ! @@cache.has_key?(xmlHelper.summary)
        @@cache[xmlHelper.summary] = {}
      end

      @@cache[xmlHelper.summary][symbol] = true

      if symbol == :finishedWork && @@cache[xmlHelper.summary].size < 2
        debug("Fedora_Worker", "WHOOPS! - #{symbol} #{xmlHelper.summary} arrived before its two chums")
      end

      if @@cache[xmlHelper.summary].size == 2
        send_solr_message("index", xmlHelper.summary)
        @@cache.delete(xmlHelper.summary)
      end
    end
  end

  def remove_from_cache(xmlHelper)
    if @@cache.has_key?(xmlHelper.summary)
      @@cache.delete(xmlHelper.summary)
      debug("Fedora_Worker", "Forgetting all about Document #{xmlHelper.summary}")
    end
  end

  def send_solr_message(command, objectID)
    info("Fedora_Worker", "sending instruction to Solr_Worker: #{command} #{objectID}")
    publish :solr_worker, "#{command} #{objectID}"
    debug("Fedora_Worker", "Cache size: #{@@cache.size}")
    @@cache.each_pair { |key, value|
      debug("Fedora_Worker", "   @cache[#{key}] = #{value}")
    }
  end

end
