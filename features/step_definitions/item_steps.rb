And /^I click the delete icon for item "(.*)"$/ do |item_handle|
  item = Item.find_by_handle(item_handle)
  find("#delete_item_#{item.id}").click
end
