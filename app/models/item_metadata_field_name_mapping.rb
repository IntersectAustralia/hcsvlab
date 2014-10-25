class ItemMetadataFieldNameMapping < ActiveRecord::Base
  attr_accessible :display_name, :rdf_name, :solr_name, :user_friendly_name

  #
  #
  #
  def self.create_or_update_field_mapping(solr_name, rdf_field_name, user_friendly_name, display_name)
    item_fields_mapping = ItemMetadataFieldNameMapping.find_or_initialize_by_solr_name(solr_name)
    item_fields_mapping.rdf_name = rdf_field_name if rdf_field_name.present?
    item_fields_mapping.user_friendly_name = user_friendly_name
    isNew = item_fields_mapping.id.nil?

    item_fields_mapping.save

    isNew
  end

  #
  #
  #
  def self.find_text_in_any_column(text)
    return ItemMetadataFieldNameMapping.where("solr_name = ? OR user_friendly_name = ? OR rdf_name = ?", text, text, text).to_a
  end
end
