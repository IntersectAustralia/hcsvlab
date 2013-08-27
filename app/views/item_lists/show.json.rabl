object @item_list
attributes :name
node(:num_items) { |item_list| item_list.get_item_ids.size }
node(:items) do |item_list|
  item_list.get_item_ids.collect { |id| catalog_url(id: id) }
end