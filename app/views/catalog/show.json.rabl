object @itemInfo
if @itemInfo.nil?
  node(:error) { "Item does not exist with given id" }
else
  node(:@context) { annotation_context_url }

  node(:"#{PROJECT_PREFIX_NAME}:catalog_url") { @itemInfo.catalog_url }

  node(:"#{PROJECT_PREFIX_NAME}:metadata") { @itemInfo.metadata }

  node(:"#{PROJECT_PREFIX_NAME}:primary_text_url") { @itemInfo.primary_text_url }

  #Only the main annotation will be shown, if it exists
  unless @itemInfo.annotations_url.nil?
  	node(:"#{PROJECT_PREFIX_NAME}:annotations_url") { @itemInfo.annotations_url }
  end
  # We are not going to show the user uploaded annotations by now
  #unless @itemInfo.annotations.nil?
  #	node(:"#{PROJECT_PREFIX_NAME}:annotations") { @itemInfo.annotations }
  #end

  node(:"#{PROJECT_PREFIX_NAME}:documents") { @itemInfo.documents }

end