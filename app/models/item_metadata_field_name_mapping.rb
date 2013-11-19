class ItemMetadataFieldNameMapping < ActiveRecord::Base
  attr_accessible :display_name, :rdf_name, :solr_name, :user_friendly_name

  #
  #
  #
  def self.find_text_in_any_column(text)
    return ItemMetadataFieldNameMapping.where("solr_name = ? OR user_friendly_name = ? OR rdf_name = ?", text, text, text).to_a
  end
end
