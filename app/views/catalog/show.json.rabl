object @item_info
if @item_info.nil?
  node(:error) { "Item does not exist with given id" }
else
  node(:@context) { annotation_context_url }

  node(:"#{PROJECT_PREFIX_NAME}:catalog_url") { @item_info.catalog_url }

  node(:"#{PROJECT_PREFIX_NAME}:metadata") { @item_info.metadata }

  node(:"#{PROJECT_PREFIX_NAME}:primary_text_url") { @item_info.primary_text_url }

  #Only the main annotation will be shown, if it exists
  unless @item_info.annotations_url.nil?
  	node(:"#{PROJECT_PREFIX_NAME}:annotations_url") { @item_info.annotations_url }
  end
  # We are not going to show the user uploaded annotations by now
  #unless @item_info.annotations.nil?
  #	node(:"#{PROJECT_PREFIX_NAME}:annotations") { @item_info.annotations }
  #end

  node(:"#{PROJECT_PREFIX_NAME}:documents") { @item_info.documents }

end