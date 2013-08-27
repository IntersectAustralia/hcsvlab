object @document
if @document.nil?
  node(:error) { "Item does not exist with given id" }
else
  node(:catalog_url) { catalog_url(@document)}
  node(:metadata) do 
    hash = {}
    values = document_show_fields(@document).select { |solr_fname, field|
      should_render_show_field? @document, field
    }
    values = values.collect do |solr_fname, field|
      key = render_document_show_field_label(@document, :field => solr_fname)
       if solr_fname == 'OLAC_language_tesim' 
          hash[key] = raw(render_language_codes(@document[solr_fname]))
       elsif solr_fname == 'DC_type' 
          hash[key] = format_duplicates(@document[solr_fname]) 
       else 
          hash[key] = render_document_show_field_value(@document, :field => solr_fname)
       end 
    end    
    do_not_display = {'id' => nil,
               'timestamp' => nil,
               MetadataHelper::short_form(MetadataHelper::RDF_TYPE) + '_tesim' => nil,
               MetadataHelper::short_form(MetadataHelper::IDENT) => nil,
        'date_group_tesim' => nil,
            'all_metadata' => nil,
               '_version_' => nil,
              'item_lists' => nil} 
    do_not_display = {} if Rails.env.development? # In development, display everything  
    do_not_display.merge!(document_show_fields(@document)) 

    @document.keys.each do |k| 
      v = @document[k] 
      unless do_not_display.has_key?(k) 
        if k == 'DC_type' 
          hash[format_key(k)] = format_duplicates(v) 
        else 
          hash[format_key(k)] = format_value(v) 
        end 
      end 
    end 
    hash
  end

  node(:primary_text_url) do
    if Item.find(@document.id).primary_text.content.nil?
      "No primary text found"
    else
      catalog_primary_text_url(@document.id, format: :json)
    end
  end

  node(:annotations_url) do
    catalog_annotations_url(@document.id, format: :json)
  end

  node(:documents) do

    data = []
    uris = [MetadataHelper::IDENTIFIER, MetadataHelper::TYPE, MetadataHelper::EXTENT, MetadataHelper::SOURCE]
    documents = item_documents(@document, uris)

    if documents.present?
      is_cooee = @document[MetadataHelper::short_form(MetadataHelper::COLLECTION)][0] == "cooee"
      type_format = get_type_format(@document, is_cooee)
      hash = {}
      documents.each do |values|
        if values.has_key?(MetadataHelper::SOURCE)
          hash[:url] = catalog_document_url(@document.id, filename: values[MetadataHelper::IDENTIFIER])
        else
          hash[:url] = values[MetadataHelper::IDENTIFIER]
        end

        #Type
        type = values[MetadataHelper::TYPE].to_s
        if values.has_key?(MetadataHelper::TYPE)
          field = values[MetadataHelper::TYPE]
          field = "unlabelled" if field == ""
          field = "Plain" if is_cooee && field == type
        else
          field = "unlabelled"
        end

        hash[:type] = sprintf(type_format, field)

        #Size
        if values.has_key?(MetadataHelper::EXTENT)
          field = values[MetadataHelper::EXTENT]
          if field.nil? || field == ""
            field = "unknown"
          else
            field = format_extent(field.to_i, 'B')
          end
        else
          field = "unknown"
        end
        hash[:size] = field.strip!
        data << hash.clone
      end

    end
    data
  end

  #if eopas_viewable? documents
  #  link_to('View in EOPAS', eopas_path)
  #end
end