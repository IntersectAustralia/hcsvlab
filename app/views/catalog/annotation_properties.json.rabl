node(:item_url) { catalog_url(@item.collection.name, @item.handle.split(':').last) }
node(:annotation_properties) { @properties }