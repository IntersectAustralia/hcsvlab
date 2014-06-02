# -*- encoding : utf-8 -*-
module Blacklight::CatalogHelperBehavior

  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG

  # Pass in an RSolr::Response (or duck-typed similar) object,
  # it translates to a Kaminari-paginatable
  # object, with the keys Kaminari views expect.
  def paginate_params(response)

    per_page = response.rows
    per_page = 1 if per_page < 1

    current_page = (response.start / per_page).ceil + 1
    num_pages = (response.total / per_page.to_f).ceil

    total_count = response.total

    start_num = response.start + 1
    end_num = start_num + response.docs.length - 1

    OpenStruct.new(:start => start_num,
                   :end => end_num,
                   :per_page => per_page,
                   :current_page => current_page,
                   :num_pages => num_pages,
                   :limit_value => per_page, # backwards compatibility
                   :total_count => total_count,
                   :first_page? => current_page > 1,
                   :last_page? => current_page < num_pages
      )
  end

  # Equivalent to kaminari "paginate", but takes an RSolr::Response as first argument.
  # Will convert it to something kaminari can deal with (using #paginate_params), and
  # then call kaminari paginate with that. Other arguments (options and block) same as
  # kaminari paginate, passed on through.
  # will output HTML pagination controls.
  def paginate_rsolr_response(response, options = {}, &block)
    pagination_info = paginate_params(response)
    paginate Kaminari.paginate_array(response.docs, :total_count => pagination_info.total_count).page(pagination_info.current_page).per(pagination_info.per_page), options, &block
  end

  #
  # shortcut for built-in Rails helper, "number_with_delimiter"
  #
  def format_num(num); number_with_delimiter(num) end

  #
  # Pass in an RSolr::Response. Displays the "showing X through Y of N" message.
  def render_pagination_info(response, options = {})
      pagination_info = paginate_params(response)

   # TODO: i18n the entry_name
      entry_name = options[:entry_name]
      entry_name ||= response.docs.first.class.name.underscore.sub('_', ' ') unless response.docs.empty?
      entry_name ||= t('blacklight.entry_name.default')


      case pagination_info.total_count
        when 0; t('blacklight.search.pagination_info.no_items_found', :entry_name => entry_name.pluralize ).html_safe
        when 1; t('blacklight.search.pagination_info.single_item_found', :entry_name => entry_name).html_safe
        else; t('blacklight.search.pagination_info.pages', :entry_name => entry_name.pluralize, :current_page => pagination_info.current_page, :num_pages => pagination_info.num_pages, :start_num => format_num(pagination_info.start), :end_num => format_num(pagination_info.end), :total_num => pagination_info.total_count, :count => pagination_info.num_pages).html_safe
      end
  end

  # Like  #render_pagination_info above, but for an individual
  # item show page. Displays "showing X of Y items" message. Actually takes
  # data from session though (not a great design).
  # Code should call this method rather than interrogating session directly,
  # because implementation of where this data is stored/retrieved may change.
  def item_page_entry_info
    t('blacklight.search.entry_pagination_info.other', :current => format_num(session[:search][:counter]), :total => format_num(session[:search][:total]), :count => session[:search][:total].to_i).html_safe
  end

  # Look up search field user-displayable label
  # based on params[:qt] and blacklight_configuration.
  def search_field_label(params)
    h( label_for_search_field(params[:search_field]) )
  end

  def current_sort_field
    blacklight_config.sort_fields[params[:sort]] || (blacklight_config.sort_fields.first ? blacklight_config.sort_fields.first.last : nil )
  end

  def current_per_page
    (@response.rows if @response and @response.rows > 0) || params.fetch(:per_page, (blacklight_config.per_page.first unless blacklight_config.per_page.blank?)).to_i
  end

  # Export to Refworks URL, called in _show_tools
  def refworks_export_url(document = @document)
    "http://www.refworks.com/express/expressimport.asp?vendor=#{CGI.escape(application_name)}&filter=MARC%20Format&encoding=65001&url=#{CGI.escape(polymorphic_path(document, :format => 'refworks_marc_txt', :only_path => false))}"
  end

  def render_document_class(document = @document)
   'blacklight-' + document.get(blacklight_config.index.record_display_type).parameterize rescue nil
  end

  def render_document_sidebar_partial(document = @document)
    render :partial => 'show_sidebar'
  end

  def has_search_parameters?
    !params[:q].blank? or !params[:f].blank? or !params[:search_field].blank?
  end

  def show_sort_and_per_page? response = nil
    response ||= @response
    response.total > 1
  end


  #
  # Internal class used to render the item information in Json format
  #
  class ItemInfo
    attr_accessor :catalog_url, :metadata, :primary_text_url, :annotations_url, :documents
  end

  #
  # Creates an instance of ItemInfo class with all the information (Metadata, PrimaryText, Documents, etc.)
  # of the given document.
  #
  def create_display_info_hash(document, userAnnotations=nil)
    default_url_options = Rails.application.config.action_mailer.default_url_options

    fieldDisplayName = create_display_field_name_mapping(document)

    # Prepare document METADATA information
    metadataHash = {}
    values = document_show_fields(document).select { |solr_fname, field|
      should_render_show_field? document, field
    }
    values = values.collect do |solr_fname, field|
      #key = render_document_show_field_label(@document, :field => solr_fname)
      key = (fieldDisplayName[solr_fname].nil?)? solr_fname : fieldDisplayName[solr_fname]

      if solr_fname == 'OLAC_language_tesim'
        metadataHash[key] = raw(render_language_codes(document[solr_fname]))
      elsif solr_fname == 'DC_type_facet'
        metadataHash[key] = format_duplicates(document[solr_fname])
      elsif solr_fname == 'date_group_facet' or solr_fname == '"full_text'
        metadataHash[:"#{PROJECT_PREFIX_NAME}:#{key}"] = render_document_show_field_value(document, :field => solr_fname)
      else
        metadataHash[key] = render_document_show_field_value(document, :field => solr_fname)
      end
    end

    do_not_display = {'id' => nil,
                      'timestamp' => nil,
                      MetadataHelper::short_form(MetadataHelper::RDF_TYPE) + '_tesim' => nil,
                      MetadataHelper::short_form(MetadataHelper::IDENT) => nil,
                      MetadataHelper::short_form(MetadataHelper::SOURCE) + '_tesim' => nil,
                      'date_group_tesim' => nil,
                      'all_metadata' => nil,
                      '_version_' => nil,
                      'all_metadata' => nil,
                      'json_metadata' => nil,
                      'discover_access_group_ssim' => nil,
                      'read_access_group_ssim' => nil,
                      'edit_access_group_ssim' => nil,
                      'discover_access_person_ssim' => nil,
                      'read_access_person_ssim' => nil,
                      'edit_access_person_ssim' => nil
    }
    #do_not_display = {} if Rails.env.development? # In development, display everything
    do_not_display.merge!(document_show_fields(document))
    document.keys.each do |k|
      v = document[k]
      unless do_not_display.has_key?(k)
        key = (fieldDisplayName[k].nil?)? k : fieldDisplayName[k]
        if k == 'DC_type_facet'
          metadataHash[key] = format_duplicates(v)
        elsif k == 'full_text' or k == 'handle'
          metadataHash[:"#{PROJECT_PREFIX_NAME}:#{key}"] = format_value(v)
        elsif k == MetadataHelper::short_form(MetadataHelper::DISPLAY_DOCUMENT) + "_tesim"
          metadataHash[:"#{PROJECT_PREFIX_NAME}:display_document"] = format_value(v)
        elsif k == MetadataHelper::short_form(MetadataHelper::INDEXABLE_DOCUMENT) + "_tesim"
          metadataHash[:"#{PROJECT_PREFIX_NAME}:indexable_document"] = format_value(v)
        else
          metadataHash[key] = format_value(v)
        end
      end
    end

    collectionName = Array(document[MetadataHelper::short_form(MetadataHelper::COLLECTION)]).first
    itemIdentifier = document[:handle].split(':').last

    # Prepare document PRIMARY_TEXT_URL information
    solr_item = Item.find_and_load_from_solr({id: document[:id]}).first
    if solr_item.hasPrimaryText?
      begin
        primary_text = catalog_primary_text_url(collectionName, format: :json)
      rescue NoMethodError => e
        # When we create the json metadata from the solr processor, we need to do the following work around
        # to have access to routes URL methods
        parameters = default_url_options.merge({format: :json})
        primary_text = Rails.application.routes.url_helpers.catalog_primary_text_url(collectionName, itemIdentifier, parameters)
      end
    else
      primary_text = "No primary text found"
    end

    # Prepare DOCUMENTS information
    documentsData = []
    uris = [MetadataHelper::IDENTIFIER, MetadataHelper::TYPE, MetadataHelper::EXTENT, MetadataHelper::SOURCE]
    documents = item_documents(document, uris)
    namespaces = RdfNamespace.get_namespaces(solr_item.collection.flat_name)

    if documents.present?
      is_cooee = document[MetadataHelper::short_form(MetadataHelper::COLLECTION)][0] == "cooee"
      type_format = get_type_format(document, is_cooee)
      documentHash = {}
      documents.each do |values|
        #URL
        if values.has_key?(MetadataHelper::SOURCE)
          begin
            documentHash[:"#{PROJECT_PREFIX_NAME}:url"] = catalog_document_url(collectionName, filename: values[MetadataHelper::IDENTIFIER])
          rescue NoMethodError => e
            # When we create the json metadata from the solr processor, we need to do the following work around
            # to have access to routes URL methods
            parameters = default_url_options.merge({filename: values[MetadataHelper::IDENTIFIER]})
            documentHash[:"#{PROJECT_PREFIX_NAME}:url"] = Rails.application.routes.url_helpers.catalog_document_url(collectionName, itemIdentifier, parameters)
          end
        else
          documentHash[:"#{PROJECT_PREFIX_NAME}:url"] = values[MetadataHelper::IDENTIFIER]
        end

        #Type
        type = values[MetadataHelper::TYPE].to_s
        if values.has_key?(MetadataHelper::TYPE)
          field = values[MetadataHelper::TYPE]
          field = "unlabelled" if field == ""
          # field = "Plain" if is_cooee && field == type
        else
          field = "unlabelled"
        end

        type_solr_name = MetadataHelper.short_form(MetadataHelper::TYPE)
        type_key = (fieldDisplayName[type_solr_name].nil?)? :type : fieldDisplayName[type_solr_name]
        documentHash[type_key] = sprintf(type_format, field)

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
        documentHash[:"#{PROJECT_PREFIX_NAME}:size"] = field.strip!

        #Other fields
        begin
          server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
          repo = server.repository(solr_item.collection.flat_name)

          query = """
            PREFIX dc:<http://purl.org/dc/terms/>
            PREFIX ausnc:<http://ns.ausnc.org.au/schemas/ausnc_md_model/>

            select * where {
              <#{solr_item.flat_uri}> ausnc:document ?doc .
              ?doc dc:identifier '#{values[MetadataHelper::IDENTIFIER]}' .
              ?doc ?property ?value
            }
          """

          sols = repo.sparql_query(query)

          fields_to_hide = [MetadataHelper::SOURCE]
          sols.each do |sol|
            if !fields_to_hide.include? sol[:property]
              prop = RdfNamespace.get_shortened_uri(sol[:property].to_s, namespaces)
              documentHash[:"#{prop}"] = sol[:value].to_s
            end
          end

        rescue => e
          Rails.logger.error e.inspect
          Rails.logger.error "Could not get document details for #{values[MetadataHelper::IDENTIFIER]}"
        end

        documentsData << documentHash.clone
      end
    end

    # Prepare ANNOTATIONS information
    #userAnnotationsData = []
    #if (userAnnotations.present?)
    #  userAnnotations.each do |aUserAnnotation|
    #    data = {}
    #    data[:name] = aUserAnnotation.original_filename
    #    data[:owner] = "#{aUserAnnotation.user.first_name} #{aUserAnnotation.user.last_name}"
    #    data[:data_uploaded] = aUserAnnotation.created_at.strftime("%d/%m/%Y %I:%M:%S %P")
    #    begin
    #      data[:url] = catalog_download_annotation_url(aUserAnnotation.id)
    #    rescue NoMethodError => e
    #      # When we create the json metadata from the solr processor, we need to do the following work around
    #      # to have access to routes URL methods
    #      data[:url] = Rails.application.routes.url_helpers.catalog_download_annotation_url(aUserAnnotation.id, default_url_options)
    #    end
    #
    #    userAnnotationsData << data
    #  end
    #end

    #Add SPARQL endpoint
    begin
      metadataHash["#{PROJECT_PREFIX_NAME}:sparqlEndpoint"] = catalog_sparqlQuery_url(collectionName)
    rescue NoMethodError => e
      metadataHash["#{PROJECT_PREFIX_NAME}:sparqlEndpoint"] = Rails.application.routes.url_helpers.catalog_sparqlQuery_url(collectionName, default_url_options)
    end


    itemInfo = ItemInfo.new
    begin
      itemInfo.catalog_url = catalog_url(collectionName, itemIdentifier)
    rescue NoMethodError => e
      # When we create the json metadata from the solr processor, we need to do the following work around
      # to have access to routes URL methods

      itemInfo.catalog_url = Rails.application.routes.url_helpers.catalog_url(collectionName, itemIdentifier, default_url_options)
    end
    itemInfo.metadata = metadataHash
    itemInfo.primary_text_url = primary_text
    begin
      unless solr_item.annotation_set.empty?
        itemInfo.annotations_url = catalog_annotations_url(collectionName, format: :json)
      end
    rescue NoMethodError => e
      # When we create the json metadata from the solr processor, we need to do the following work around
      # to have access to routes URL methods
      parameters = default_url_options.merge({format: :json})
      itemInfo.annotations_url = Rails.application.routes.url_helpers.catalog_annotations_url(collectionName, itemIdentifier, parameters)
    end
    #if (!userAnnotationsData.empty?)
    #  itemInfo.annotations = {} if itemInfo.annotations.nil?
    #  itemInfo.annotations[:user_annotationes] = userAnnotationsData
    #end


    itemInfo.documents = documentsData

    itemInfo
  end

  #
  # Query the ItemMetadataFieldNameMapping table and creates a hash containing the rdf_name and the user_friendly_name
  # This will avoid querying the table for each single field.
  #
  def create_display_field_name_mapping(document)
    fieldsMapping = {}
    ItemMetadataFieldNameMapping.all.each do |anItemField|
      fieldsMapping[anItemField.solr_name] = {rdf_name:anItemField.rdf_name, user_friendly_name:anItemField.user_friendly_name}
    end

    fieldDisplayName = {}
    document.keys.each do |k|
      fieldMapping = fieldsMapping[k]
      if (!fieldMapping.nil? && fieldMapping[:rdf_name].present?)
        fieldDisplayName[k] = fieldMapping[:rdf_name]
      elsif (!fieldMapping.nil? && fieldMapping[:user_friendly_name].present?)
        fieldDisplayName[k] = fieldMapping[:user_friendly_name]
      elsif (document_show_fields(document).include?(k))
        fieldDisplayName[k] = render_document_show_field_label(document, :field => k)
      end
    end
    fieldDisplayName
  end

end
