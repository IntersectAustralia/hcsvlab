object @item_list
attributes :name
node(:num_items) { |item_list| item_list.get_item_handles.size }
node(:items) do |item_list|
  item_list.get_item_handles.collect { |handle| catalog_url(handle.split(':').first, handle.split(':').last) }
end