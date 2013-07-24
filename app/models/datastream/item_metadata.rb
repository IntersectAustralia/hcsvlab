class Datastream::ItemMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "fields")
    t.collection(index_as: :stored_searchable)
    t.collection_id(index_as: :stored_searchable)
  end

  def self.xml_template
    Nokogiri::XML.parse("<fields/>")
  end
end