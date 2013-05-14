class MediaItem

  class Person
    attr_accessor :full_name
  end
  # belongs_to :depositor, :class_name => 'User'
  # has_many :transcripts, :dependent => :nullify

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

  attr_reader :title, :description, :recorded_on, :copyright, :license, :private, :format, :media, :media_cache, :depositor

  def initialize(attributes)
    @title = attributes['title']
    @description = attributes['description']
    @recorded_on = attributes['created']
    @copyright = attributes['rights']
    @license = attributes['accessRights']
    @depositor = Person.new
    @depositor.full_name = attributes['depositor']
    @format = 'video'
    @media = attributes['media']
    # @media_cache
  end

end