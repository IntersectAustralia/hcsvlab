class ItemMetadataFieldNameMapping < ActiveRecord::Base
  attr_accessible :display_name, :rdf_name, :solr_name, :user_friendly_name

  #
  #
  #
  def self.create_or_update_field_mapping(solr_name, rdf_field_name, user_friendly_name)
    item_fields_mapping = ItemMetadataFieldNameMapping.find_or_initialize_by_solr_name(solr_name)
    is_new = item_fields_mapping.id.nil?
    # No point committing if the values are the same. Helps to clear up the log
    unless item_fields_mapping.rdf_name.eql?(rdf_field_name) && item_fields_mapping.user_friendly_name.eql?(user_friendly_name)
      item_fields_mapping.rdf_name = rdf_field_name if rdf_field_name.present?
      item_fields_mapping.user_friendly_name = user_friendly_name
      item_fields_mapping.save
    end

    is_new
  end

  #
  #
  #
  def self.find_text_in_any_column(text)
    return ItemMetadataFieldNameMapping.where("solr_name = ? OR user_friendly_name = ? OR rdf_name = ?", text, text, text).to_a
  end
end
