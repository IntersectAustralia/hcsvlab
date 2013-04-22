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

private

  def genRE(tag)
    return /<#{tag} type="text">([\w-\:]+)<\/#{tag}>/
  end

  def extract(regexp)
    match = regexp.match(xml)
    return match[1] unless match == nil
    return nil
  end
end
