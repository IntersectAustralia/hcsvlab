# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
HcsvlabWeb::Application.initialize!

# # Set up a better logger (i.e. one which timestamps the messages)
# Rails.logger = TimestampingLogger.new(Rails.logger)

# Define WARC file type
Mime::Type.register "application/warc", :warc
