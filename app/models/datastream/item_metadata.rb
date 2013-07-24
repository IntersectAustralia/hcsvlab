class Datastream::ItemMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "fields")
    t.collection
    t.collection_id
  end

  def self.xml_template
    Nokogiri::XML.parse("<fields/>")
  end
end