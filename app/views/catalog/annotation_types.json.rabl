node(:item_url) { catalog_url(@item.collection.name, @item.handle.first.split(':').last) }
node(:annotation_types) { @types }