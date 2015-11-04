module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name, options = {})
    case page_name

      when /^the home\s?page$/
        root_path(options)

      # User paths
      when /^the login page$/
        new_user_session_path(options)

      when /^the logout page$/
        destroy_user_session_path(options)

      when /^the user profile page$/
        users_profile_path(options)

      when /^the request account page$/
        new_user_registration_path(options)

      when /^the edit my details page$/
        edit_user_registration_path(options)

      when /^the user details page for (.*)$/
        user_path(User.where(:email => $1).first, options)

      when /^the edit role page for (.*)$/
        edit_role_user_path(User.where(:email => $1).first, options)

      when /^the reset password page$/
        edit_user_password_path(options)

      when /^the forgot password page$/
        new_user_password_path(options)

      when /^the access requests page$/
        access_requests_users_path(options)

      when /^the list users page$/
        users_path(options)

      when /^the item lists page$/
        item_lists_path(options)

      when /^the item list page for "(.*)"$/
        attempts = 10
        itemList = nil
        count=0
        while (itemList.nil? and count < attempts)
          itemList = ItemList.find_by_name($1)
          count = count + 1
          puts "######## ItemList '#{($1)}' not found, retying in 5 secs." if itemList.nil?
          sleep 5 if itemList.nil?
        end
        item_list_path(itemList, options)

      when /^the item list page for item list "(.*)"$/
        item_list_path($1, options)

      when /^the catalog page$/
        catalog_index_path(options)

      when /^the catalog annotations page for "(.*)"$/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        catalog_annotations_path(collectionName, itemIdentifier, options)

      when /^the catalog annotation properties page for "(.*)"$/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        catalog_annotation_properties_path(collectionName, itemIdentifier, options)

      when /^the catalog annotation types page for "(.*)"$/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        catalog_annotation_types_path(collectionName, itemIdentifier, options)

      when /^the catalog primary text page for "(.*)"$/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        catalog_primary_text_path(collectionName, itemIdentifier, options)

      when /^the catalog page for "(.*)"$/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        catalog_path(collectionName, itemIdentifier, options)

      when /^the catalog sparql page for collection "(.*)"$/
        catalog_sparqlQuery_path($1, options)

      when /^the download_items page$/
        catalog_download_items_api_path(options)

      when /^the searchable fields page$/
        catalog_searchable_fields_path(options)

      when /^the licences page$/
        licences_path(options)

      when /^the collection page for "(.*)"$/
        collection_path($1, options)

      when /^the collection page for id "(.*)"$/
        collection_path($1, options)

      when /^the collections page$/
        collections_path(options)

      when /^the create collection page$/
        web_create_collection_path(options)

      when /^the delete item "(.*)" from collection "(.*)" page/
        delete_collection_item_path($2, $1, options)

      when /^the delete item web path for "(.*)"$/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        delete_item_web_path(collectionName, itemIdentifier, options)

      when /^the delete document "(.*)" from "item "(.*)" in collection "(.*)" page/
        delete_item_document_path($3, $2, $1, options)

      when /^the delete document web path for "(.*)" in "(.*)"$/
        collectionName = $2.split(':').first
        itemIdentifier = $2.split(':').last
        delete_item_document_web_path(collectionName, itemIdentifier, $1, options)

      when /^the update item page for "(.*)"/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        update_collection_item_path(collectionName, itemIdentifier, options)

      when /^the add document to item page for "(.*)"/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        add_item_document_path(collectionName, itemIdentifier, options)

      when /^the licence agreements page$/
        account_licence_agreements_path(options)

      when /^the download api key page$/
        account_api_key_path

      when /^the generate api key page$/
        account_generate_token_path

      when /^the document content page for file "(.*)" for item "(.*)"$/
        collectionName = $2.split(':').first
        itemIdentifier = $2.split(':').last
        catalog_document_path(collectionName, itemIdentifier, $1, options)

      when /^the admin page$/
        admin_index_path(options)

      when /^the search history page$/
        search_history_path(options)

      when /^the eopas page for item "(.*)"$/
        collectionName = $1.split(':').first
        itemIdentifier = $1.split(':').last
        eopas_path(collectionName, itemIdentifier, options)

      when /^the licence requests page$/
        user_licence_requests_path(options)

      when /^the view metrics page$/
        view_metrics_path(options)

      when /^the share item list page for "([^"]*)"$/
        item_list = ItemList.find_by_name($1)
        share_item_list_path(item_list)

      when /^the unshare item list page for "([^"]*)"$/
        item_list = ItemList.find_by_name($1)
        unshare_item_list_path(item_list)

      when /^the clear item list page for "([^"]*)"$/
        item_list = ItemList.find_by_name($1)
        clear_item_list_path(item_list)

      when /^the document audit page$/
        document_audit_path(options)

      when /^the transfer spec page for item list "([^"]*)"$/
        item_list = ItemList.find_by_name($1)
        aspera_transfer_spec_item_list_path(item_list)

# Add more mappings here.
# Here is an example that pulls values out of the Regexp:
#
#   when /^(.*)'s profile page$/i
#     user_profile_path(User.find_by_login($1))

      else
        begin
          page_name =~ /^the (.*) page$/
          path_components = $1.split(/\s+/)
          self.send(path_components.push('path').join('_').to_sym)
        rescue NoMethodError, ArgumentError
          raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
                    "Now, go and add a mapping in #{__FILE__}"
        end
    end
  end
end

World(NavigationHelpers)
