class Datastream::ItemMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "fields")
  end

  def self.xml_template
    Nokogiri::XML.parse("<fields/>")
  end
end