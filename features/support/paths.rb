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

      when /^the access requests page$/
        access_requests_users_path(options)

      when /^the list users page$/
        users_path(options)

      when /^the item lists page$/
        item_lists_path(options)

      when /^the item list page for "(.*)"$/
        attempts = 10
        itemList = nil
        x=0
        while (itemList.nil? and x < attempts)
          itemList = ItemList.find_by_name($1)
          x = x + 1
          sleep 1000 if itemList.nil?
        end
        item_list_path(itemList, options)

      when /^the catalog page$/
        catalog_index_path(options)

      when /^the catalog annotations page for "(.*)"$/
        catalog_annotations_path(Item.find($1), options)

      when /^the catalog primary text page for "(.*)"$/
        catalog_primary_text_path(Item.find($1), options)

      when /^the catalog page for "(.*)"$/
        catalog_path(Item.find($1), options)

      when /^the licences page$/
        licences_path(options)

      when /^the collection page for "(.*)"$/
        collection_path(Collection.find_by_short_name($1), options)

      when /^the collections page$/
        collections_path(options)

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
