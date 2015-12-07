object @item
node(:@context) { annotation_context_url }
node(:"#{PROJECT_PREFIX_NAME}:catalog_url") { catalog_url(@item.collection.name, @item.get_name) }
node(:"#{PROJECT_PREFIX_NAME}:metadata") { "processing" }