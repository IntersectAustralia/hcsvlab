collection @item_lists
attributes :name
node(:item_list_url) { |item_list| item_list_url(item_list) }
node(:num_items) do |item_list| 
  item_list.get_item_ids.size
end
