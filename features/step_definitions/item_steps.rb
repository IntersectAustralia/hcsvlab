And /^I click the delete icon for item "(.*)"$/ do |item_handle|
  item = Item.find_by_handle(item_handle)
  find("#delete_item_#{item.id}").click
end
And /^I click the delete icon for document "(.*)" of item "(.*)"$/ do |document_filename, item_handle|
  item = Item.find_by_handle(item_handle)
  document = item.documents.find_by_file_name(document_filename)
  find("#delete_document_#{document.id}").click
end
