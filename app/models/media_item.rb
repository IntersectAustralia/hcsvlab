class MediaItem < ActiveRecord::Base

  has_no_table

  # belongs_to :depositor, :class_name => 'User'
  has_many :transcripts, :dependent => :nullify

  # # Access AREL so we can do an OR without writing SQL
  # scope :current_user_and_public, lambda { |user|
  #   if user
  #     where(
  #       arel_table[:private].eq(false).
  #       or(arel_table[:depositor_id].eq(user.id))
  #     )
  #   else
  #     where(:private => false)
  #   end
  # }

  # mount_uploader :media, MediaUploader
  # process_in_background :media

  attr_accessor :title, :description, :recorded_on, :copyright, :license, :format, :media, :depositor
  attr_accessible :title, :description, :recorded_on, :copyright, :license, :format, :media, :depositor 

end