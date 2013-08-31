class Datastream::CollectionMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "fields")
    t.uri(index_as: :stored_searchable)
    t.short_name(index_as: :stored_searchable)
    t.private_data_owner(index_as: :stored_searchable)
    t.privacy_status(index_as: :stored_searchable)
  end

  def self.xml_template
    Nokogiri::XML.parse("<fields/>")
  end
end