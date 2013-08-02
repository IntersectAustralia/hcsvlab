class Datastream::LicenseMetadata < ActiveFedora::OmDatastream

	set_terminology do |t|
		t.root(path: "fields")
		t.name(index_as: :stored_searchable)
		t.text(index_as: :stored_searchable)
    t.type(index_as: :stored_searchable)
    t.ownerId(index_as: :stored_searchable)
    t.ownerEmail(index_as: :stored_searchable)
	end

	def self.xml_template
		Nokogiri::XML.parse("<fields/>")
	end
end