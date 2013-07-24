class Datastream::DocumentMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "fields")
    t.file_name(index_as: :stored_searchable)
    t.type(index_as: :stored_searchable)
    t.mime_type(index_as: :stored_searchable)
  end

  def self.xml_template
    Nokogiri::XML.parse("<fields/>")
  end
end