class IssueReport

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :user_email, :description, :url, :screenshot, :timestamp, :include_screenshot
  validates_presence_of :user_email
  validates_presence_of :url
  validates_presence_of :description
  validates_length_of :description, :maximum => 10.kilobytes

  def initialize(attributes = {})
    @url  = attributes[:url]
    @user_email  = attributes[:user_email]
    @description = attributes[:description]
    @screenshot = attributes[:screenshot]
    @include_screenshot = attributes[:include_screenshot]
  end

  def persisted?
    false
  end

end