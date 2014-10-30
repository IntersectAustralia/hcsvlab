class Item < ActiveRecord::Base

  has_many :documents

  belongs_to :collection

  validates :uri, presence: true
  validates :handle, presence: true, uniqueness: {case_sensitive: false}

  scope :unindexed, where(indexed_at: nil)
  scope :indexed, where('indexed_at is not null')

  def has_primary_text?
    self.primary_text_path.present?
  end

  #
  # The list of Item fields which we should not show to the user.
  #
  def self.development_only_fields
    ['id',
     'timestamp',
     'full_text',
     MetadataHelper::short_form(MetadataHelper::RDF_TYPE) + '_tesim',
     'handle',
     '_version_',
     'all_metadata',
     'discover_access_group_ssim',
     'read_access_group_ssim',
     'edit_access_group_ssim',
     'discover_access_person_ssim',
     'read_access_person_ssim',
     'edit_access_person_ssim',
     "json_metadata",
     "score",
     MetadataHelper::short_form(MetadataHelper::DISPLAY_DOCUMENT) + '_tesim',
     MetadataHelper::short_form(MetadataHelper::INDEXABLE_DOCUMENT) + '_tesim']
  end
end
