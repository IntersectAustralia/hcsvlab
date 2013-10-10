class Datastream::ItemMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "fields")
    t.identifier(index_as: :stored_searchable)
    t.handle(index_as: :stored_searchable)
  end

  def self.xml_template
    Nokogiri::XML.parse("<fields/>")
  end
end