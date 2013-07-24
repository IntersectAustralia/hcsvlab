class Datastream::DocumentMetadata < ActiveFedora::OmDatastream

  set_terminology do |t|
    t.root(path: "fields")
    t.file_name
    t.type
    t.mime_type
  end

  def self.xml_template
    Nokogiri::XML.parse("<fields/>")
  end
end