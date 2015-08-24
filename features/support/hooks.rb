require 'fileutils'

# delete the api created collections after each test which makes them
After('@api_create_collection') do
  if Dir.exists?(Rails.application.config.api_collections_location)
    FileUtils.remove_dir(Rails.application.config.api_collections_location)
  end
end