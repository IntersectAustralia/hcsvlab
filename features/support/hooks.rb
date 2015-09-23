require 'fileutils'

# delete the api created collections after each test which makes them
After('@api_create_collection, @api_add_item, @api_delete_item, @api_edit_collection') do
  if Dir.exists?(Rails.application.config.api_collections_location)
    FileUtils.remove_dir(Rails.application.config.api_collections_location)
  end
end