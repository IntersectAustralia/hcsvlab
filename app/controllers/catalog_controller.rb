# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'yaml'
require "#{Rails.root}/lib/item/download_items_helper.rb"

class CatalogController < ApplicationController

  FIXNUM_MAX = 2147483647

  # Set catalog tab as current selected
  set_tab :catalog

  before_filter :authenticate_user!, :except => [:index, :annotation_context, :searchable_fields]
  #load_and_authorize_resource

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::CatalogHelperBehavior

  include Item::DownloadItemsHelper
  include ERB::Util

  # These before_filters apply the hydra access controls
  before_filter :wrapped_enforce_show_permissions, :only=>[:show, :document, :primary_text, :annotations]
  # This applies appropriate access controls to all solr queries
  CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]
  # This filters out objects that you want to exclude from search results, like FileAssets
  CatalogController.solr_search_params_logic += [:exclude_unwanted_models]

  configure_blacklight do |config|
    config.default_solr_params = {
        :qt => 'search',
        :rows => 20
    }

    # solr field configuration for search results/index views
    config.index.show_link = solr_name('DC_identifier', :stored_searchable, type: :string)
    config.index.record_tsim_type = 'has_model_ssim'

    # solr field configuration for document/show views
    config.show.html_title = 'title_tesim'
    config.show.heading = 'title_tesim'
    config.show.display_type = 'has_model_ssim'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _tsimed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar

    facetsConfig = YAML.load_file(Rails.root.join("config", "facets.yml"))
    facetsConfig[:facets].each do |aFacetConfig|
      config.add_facet_field aFacetConfig[:name], :label => aFacetConfig[:label], :limit => aFacetConfig[:limit], :partial => aFacetConfig[:partial]
    end

    #config.add_facet_field 'DC_is_part_of', :label => 'Corpus', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'date_group', :label => 'Created', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'AUSNC_mode', :label => 'Mode', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'AUSNC_speech_style', :label => 'Speech Style', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'AUSNC_interactivity', :label => 'Interactivity', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'AUSNC_communication_context', :label => 'Communication Context', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'AUSNC_audience', :label => 'Audience', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'OLAC_discourse_type', :label => 'Discourse Type', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'OLAC_language', :label => 'Language (ISO 639-3 Code)', :limit => 2000, :partial => 'catalog/sorted_facet'
    #config.add_facet_field 'DC_type', :label => 'Type', :limit => 2000, :partial => 'catalog/sorted_facet'

    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.default_solr_params[:'facet.field'] = config.facet_fields.keys
    #use this instead if you don't want to query facets marked :show=>false
    #config.default_solr_params[:'facet.field'] = config.facet_fields.select{ |k, v| v[:show] != false}.keys


    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 

    #
    # Item fields
    #

    # config.add_index_field solr_name('http://purl.org/dc/terms/isPartOf', :stored_searchable), :label => 'Corpus:' 
    # config.add_index_field solr_name('http://purl.org/dc/terms/identifier', :stored_searchable, type: :string), :label => 'Identifier:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/title', :stored_searchable, type: :string), :label => 'Title:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/created', :stored_searchable, type: :string), :label => 'Created:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/type', :stored_searchable, type: :string), :label => 'Type:'

    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/mode', :stored_searchable, type: :string), :label => 'Mode:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/speech_style', :stored_searchable), :label => 'Speech Style:' 
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/interactivity', :stored_searchable), :label => 'Interactivity:' 
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/communication_context', :stored_searchable), :label => 'Communication Context:' 
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/audience', :stored_searchable), :label => 'Audience:' 
    # config.add_index_field solr_name('http://www.language-archives.org/OLAC/1.1/discourse_type', :stored_searchable), :label => 'Discourse Type:' 

    # config.add_index_field solr_name('http://www.w3.org/1999/02/22-rdf-syntax-ns#type', :stored_searchable, type: :string), :label => 'RDF Type:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ace/genre', :stored_searchable, type: :string), :label => 'Genre:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/audience', :stored_searchable, type: :string), :label => 'Audience:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/communication_setting', :stored_searchable, type: :string), :label => 'Communication Setting:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/document', :stored_searchable, type: :string), :label => 'Documents:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/itemwordcount', :stored_searchable, type: :string), :label => 'Word Count'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/plaintextversion', :stored_searchable, type: :string), :label => 'Plain Text:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/publication_status', :stored_searchable, type: :string), :label => 'Publication Status:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/source', :stored_searchable, type: :string), :label => 'Source:'
    # config.add_index_field solr_name('http://ns.ausnc.org.au/schemas/ausnc_md_model/written_mode', :stored_searchable, type: :string), :label => 'Written Mode:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/contributor', :stored_searchable, type: :string), :label => 'Contributor:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/identifier', :stored_searchable, type: :string), :label => 'Identifier:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/isPartOf', :stored_searchable, type: :string), :label => 'Corpus:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/publisher', :stored_searchable, type: :string), :label => 'Publisher:'

    # config.add_index_field solr_name('http://purl.org/dc/terms/extent', :stored_searchable, type: :string), :label => 'Extent:'
    # config.add_index_field solr_name('http://purl.org/dc/terms/source', :stored_searchable, type: :string), :label => 'Source:'
    # config.add_index_field solr_name('Item', :stored_searchable, type: :string), :label => 'Item:'

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 

    config.add_show_field solr_name('DC_title', :stored_searchable, type: :string), :label => 'Title'
    config.add_show_field solr_name('DC_created', :stored_searchable, type: :string), :label => 'Created'
    config.add_show_field solr_name('DC_identifier', :stored_searchable, type: :string), :label => 'Identifier'
    config.add_show_field 'HCSvLab_collection_facet', :label => 'Collection'
    config.add_show_field solr_name('DC_Source', :stored_searchable, type: :string), :label => 'Source'
    config.add_show_field solr_name('AUSNC_itemwordcount', :stored_searchable, type: :string), :label => 'Word Count'

    config.add_show_field 'AUSNC_mode_facet', :label => 'Mode'
    config.add_show_field 'AUSNC_speech_style_facet', :label => 'Speech Style'
    config.add_show_field 'AUSNC_interactivity_facet', :label => 'Interactivity'
    config.add_show_field 'AUSNC_communication_context_facet', :label => 'Communication Context'
    config.add_show_field solr_name('AUSNC_discourse_type', :stored_searchable), :label => 'Discourse Type'
    config.add_show_field 'OLAC_discourse_type_facet', :label => 'Discourse Type'
    config.add_show_field 'OLAC_language_facet', :label => 'Language (ISO 639-3 Code)'

    config.add_show_field solr_name('ACE_genre', :stored_searchable, type: :string), :label => 'Genre'
    config.add_show_field 'AUSNC_audience_facet', :label => 'Audience'
    config.add_show_field 'AUSNC_communication_setting_facet', :label => 'Communication Setting'
    config.add_show_field 'AUSNC_communication_medium_facet', :label => 'Communication Medium'
    config.add_show_field solr_name('AUSNC_plaintextversion', :stored_searchable, type: :string), :label => 'Plain Text'
    config.add_show_field 'AUSNC_publication_status_facet', :label => 'Publication Status'
    config.add_show_field solr_name('AUSNC_source', :stored_searchable, type: :string), :label => 'Source'
    config.add_show_field 'AUSNC_written_mode_facet', :label => 'Written Mode'
    config.add_show_field solr_name('DC_contributor', :stored_searchable, type: :string), :label => 'Contributor'
    config.add_show_field solr_name('DC_publisher', :stored_searchable, type: :string), :label => 'Publisher'

    config.add_show_field solr_name('AUSNC_document', :stored_searchable, type: :string), :label => 'Documents'
    config.add_show_field 'DC_type_facet', :label => 'Type'
    config.add_show_field solr_name('DC_extent', :stored_searchable, type: :string), :label => 'Extent'
    config.add_show_field solr_name('Item', :stored_searchable, type: :string), :label => 'Item'

    config.add_show_field 'date_group_facet', :label => 'Date Group'

    # solr fields to be displayed in the show (single result) view
    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 

    #    config.add_search_field 'all_fields', :label => 'All Fields'
    config.add_search_field('all_fields', :label => 'All Fields') { |field|
#      field.solr_parameters = { :'spellcheck.dictionary' => 'full text' }
      field.solr_local_parameters = {
          :qf => '$all_fields_qf',
          :pf => '$all_fields_pf'
      }
    }

#    config.add_search_field('all_metadata', :label => 'All Metadata') { |field|
##      field.solr_parameters = { :'spellcheck.dictionary' => 'full text' }
#      field.solr_local_parameters = { 
#        :qf => 'all_metadata',
#        :pf => ''
#      }
#    }
#    config.add_search_field('full_text', :label => 'Text Document') { |field|
##      field.solr_parameters = { :'spellcheck.dictionary' => 'full text' }
#      field.solr_local_parameters = { 
#        :qf => 'full_text',
#        :pf => ''
#      }
#    }

# Now we see how to over-ride Solr request handler defaults, in this
# case for a BL "search field", which is really a dismax aggregate
# of Solr search fields.

#    config.add_search_field('Title') do |field|
#      # solr_parameters hash are sent to Solr as ordinary url query params. 
#      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }
#
#      # :solr_local_parameters will be sent using Solr LocalParams
#      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
#      # Solr parameter de-referencing like $title_qf.
#      # See: http://wiki.apache.org/solr/LocalParams
#      field.solr_local_parameters = { 
#        :qf => '$title_qf',
#        :pf => '$title_pf'
#      }
#    end

# Specifying a :qt only to show it's possible, and so our internal automated
# tests can test it. In this case it's the same as
# config[:default_solr_parameters][:qt], so isn't actually neccesary.
#    config.add_search_field('author', :label => 'Author') do |field|
#      # field.solr_parameters = { :'spellcheck.dictionary' => 'contributor' }
#      field.qt = 'search'
#      field.solr_local_parameters = { 
#        :qf => '$author_qf',
#        :pf => '$author_pf'
#      }
#    end
#
#    config.add_search_field('full_text', :label => "Full Text") do |field|
#      # field.solr_parameters = { :'spellcheck.dictionary' => 'full text' }
#      field.solr_local_parameters = { 
#        :qf => 'full_text',
#        :pf => '$full_text_pf'
#      }
#    end


# "sort results by" select (pulldown)
# label in pulldown is followed by the name of the SOLR field to sort by and
# whether the sort is ascending or descending (it must be asc or desc
# except in the relevancy case).
#    config.add_sort_field 'score desc, pub_date_dtsi desc, title_tesi asc', :label => 'relevance'
#    config.add_sort_field 'http://purl.org/dc/terms/isPartOf_sim', :label => 'Corpus' 
#    config.add_sort_field 'http://purl.org/dc/terms/title_tesim', :label => 'Title'
#    config.add_sort_field 'http://purl.org/dc/terms/contributor', :label => 'Contributor'

# If there are more than this many search results, no spelling ("did you
# mean") suggestion is offered.
    config.spell_max = 5
  end

  # override default index method
  def index
    begin
      metadataSearchParam = params[:metadata]
      if (!metadataSearchParam.nil? and !metadataSearchParam.empty?)
        if (metadataSearchParam.include?(":"))
          metadataSearchParam.gsub!(/\sor\s/, " OR ")
          metadataSearchParam.gsub!(/\sand\s/, " AND ")

          params[:fq] = processMetadataParameters(metadataSearchParam.clone)
          Rails.logger.debug("Sending metadata search with parametes #{params[:fq]}")
        else
          params[:fq] = "all_metadata:(#{metadataSearchParam})"
        end
        self.solr_search_params_logic += [:add_metadata_extra_filters]
      end

      bench_start = Time.now
      super
      bench_end = Time.now
      @profiler = ["Time for catalog search with params: f=#{params['f']} q=#{params['q']} took: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]
      Rails.logger.debug(@profiler.first)

      params.delete(:fq)
    rescue RSolr::Error::Http => e
      Rails.logger.debug(e.message)
      Rails.logger.debug(e.backtrace)
      flash[:error] = "Sorry, error in search parameters."
      redirect_to root_url and return

    end

    if !current_user.nil?
      @hasAccessToEveryCollection = true
      @hasAccessToSomeCollections = false
      Collection.all.each do |aCollection|
        #I have access to a collection if I am the owner or if I accepted the licence for that collection
        hasAccessToCollection = (aCollection.flat_ownerEmail.eql? current_user.email) ||
                                (current_user.has_agreement_to_collection?(aCollection, UserLicenceAgreement::DISCOVER_ACCESS_TYPE, false))

        @hasAccessToSomeCollections = @hasAccessToSomeCollections || hasAccessToCollection
        @hasAccessToEveryCollection = @hasAccessToEveryCollection && hasAccessToCollection
      end
    end
  end

  #
  # override default show method to allow for json response
  #
  def show
    if Item.where(id: params[:id]).count != 0
      @response, @document = get_solr_response_for_doc_id


      #By now we are not going to show user uploaded annotation in the webapp
      #solr_item = Item.find_and_load_from_solr({id: @document[:id]}).first
      #@has_main_annotation = !solr_item.annotation_set.empty?

      #@user_annotations = UserAnnotation.find_all_by_item_identifier(@document[:handle])

    else
      respond_to do |format|
        format.html {
          flash[:error] = "Sorry, you have requested a record that doesn't exist."
          redirect_to root_url and return
        }
        format.json { render :json => {:error => "not-found"}.to_json, :status => 404 }
      end
      return
    end
    respond_to do |format|
      format.html { setup_next_and_previous_documents }
      format.json {}
      # Add all dynamically added (such as by document extensions)
      # export formats.
      if !@document.nil?

        @itemInfo = create_display_info_hash(@document, @user_annotations)

        @document.export_formats.each_key do |format_name|
          # It's important that the argument to send be a symbol;
          # if it's a string, it makes Rails unhappy for unclear reasons. 
          format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
        end
      end
    end
  end

  def search
    request.format = 'json'
    metadataSearchParam = params[:metadata]
    if (!metadataSearchParam.nil? and !metadataSearchParam.empty?)
      if (metadataSearchParam.include?(":"))
        metadataSearchParam.gsub!(/\sor\s/, " OR ")
        metadataSearchParam.gsub!(/\sand\s/, " AND ")

        params[:fq] = processMetadataParameters(metadataSearchParam.clone)
      else
        params[:fq] = "all_metadata:(#{metadataSearchParam})"
      end
    end
    self.solr_search_params_logic += [:add_metadata_extra_filters]
    self.solr_search_params_logic += [:add_unlimited_rows]

    # This will allow to search via the API using the parameter q, as it is use via the user-interface
    if (params[:q].present?)
      params[:q] = "{!qf=$all_fields_qf pf=$all_fields_pf}#{params[:q]}"
    end

    begin
      (@response, document_list) = get_search_results params
    rescue Exception => e
      respond_to do |format|
        format.any { render :json => {:error => "bad-query"}.to_json, :status => 400 }
      end
      return
    end

    respond_to do |format|
      format.json {}
    end
  end

  def annotations
    bench_start = Time.now
    if Item.where(id: params[:id]).count != 0
      @response, @document = get_solr_response_for_doc_id
    end
    begin
      @item = Item.find_and_load_from_solr({:id=>params[:id]}).first

      if !@item.datastreams["annotationSet1"].nil?
        @anns, @annotates_document = query_annotations(@item, @document, params[:type], params[:label])

        respond_to do |format|
            format.json {}
        end
        return
      end
    rescue Exception => e
        # Fall through to return Not Found
    end
    respond_to do |format|
        format.json { render :json => {:error => "not-found"}.to_json, :status => 404 }
    end
    bench_end = Time.now
    Rails.logger.debug("Time for retrieving annotations for #{params[:id]} took: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
  end

  def annotation_context

    avoid_context = collect_restricted_predefined_vocabulary

    @vocab_hash = {}
    RDF::Vocabulary.each {|vocab|
      if (!avoid_context.include?(vocab.to_uri) and vocab.to_uri.qname.present?)
        prefix = vocab.to_uri.qname.first.to_s
        uri = vocab.to_uri.to_s
        @vocab_hash[prefix] = {:@id => uri}
      end
    }
    request.format = 'json'
    respond_to 'json'

  end

  def primary_text
    bench_start = Time.now
    begin
      item = Item.find_and_load_from_solr({id: params[:id]}).first

      response.header["Content-Length"] = item.primary_text.content.length.to_s
      send_data item.primary_text.content, type: 'text/plain', filename: item.primary_text.label

      bench_end = Time.now
      Rails.logger.debug("Time for retrieving primary text for #{params[:id]} took: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    rescue Exception => e
      respond_to do |format|
        format.html { flash[:error] = "Sorry, you have requested a document for an item that doesn't exist."
                      redirect_to root_path and return }
        format.any { render :json => {:error => "not-found"}.to_json, :status => 404 }
      end
    end
  end

  def document
    begin
      doc = Document.find_and_load_from_solr({:file_name=>params[:filename].to_s, item: params[:id]}).first

      if (!doc.nil?)
        params[:disposition] = 'Inline'
        params[:disposition].capitalize!

        # If HTTP_RANGE variable is set, we need to send partial content and tell the browser
        # what fragment of the file we are sending by using the variables Content-Range and
        # Content-Length
        if(request.headers["HTTP_RANGE"])
          size = doc.datastreams['CONTENT1'].content.size
          bytes = Rack::Utils.byte_ranges(request.headers, size)[0]
          offset = bytes.begin
          length = bytes.end  - bytes.begin

          response.header["Accept-Ranges"] =  "bytes" # Tells the browser that we accept partial content
          response.header["Content-Range"] = "bytes #{bytes.begin}-#{bytes.end}/#{size}"
          response.header["Content-Length"] = (length+1).to_s
          response.status = :partial_content

          content = doc.datastreams['CONTENT1'].content[offset, length+1]
        else
          content = doc.datastreams['CONTENT1'].content
          response.header["Content-Length"] = Rack::Utils.bytesize(content).to_s

        end

        send_data content,
                  :disposition => params[:disposition],
                  :filename => doc.file_name[0].to_s,
                  :type => doc.datastreams['CONTENT1'].mimeType.to_s

        return
      end
    rescue Exception => e
      Rails.logger.error(e.backtrace)
        # Fall through to return Not Found
    end
    respond_to do |format|
        #format.html { raise ActionController::RoutingError.new('Not Found') }
        format.html { flash[:error] = "Sorry, you have requested a document that doesn't exist." 
                      redirect_to catalog_path(params[:id]) and return}
        format.any { render :json => {:error => "not-found"}.to_json, :status => 404 }
    end
  end

  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
  def invalid_solr_id_error
    respond_to do |format|
      format.html { flash[:error] = "Sorry, you have requested a document that doesn't exist."
                    params.delete(:id)
                    redirect_to catalog_path() and return
                  }
      format.any { render :json => {:error => "not-found"}.to_json, :status => 404 }
    end
  end

  #
  # This is an API method for downloading items' documents and metadata
  #
  def download_items
    if (params[:items].present?)

      itemsId = params[:items].collect { |x| File.basename(x) }

      respond_to do |format|
        format.warc {
          render :json => {:error => "Not Implemented"}.to_json, :status => 501
          #download_as_warc(itemsId)clear
        }
        format.any {
          download_as_zip(itemsId, "items.zip")
        }
      end
    else
      respond_to do |format|
        format.any { render :json => {:error => "Bad Request"}.to_json, :status => 400 }
      end
    end

  end

  #
  # Display every field that can be user to do a search in the metadata
  #
  def searchable_fields
    @nameMappings = []
    ItemMetadataFieldNameMapping.all.each do |aNameMapping|
      @nameMappings << {rdfName: aNameMapping['rdf_name'], user_friendly_name: aNameMapping['user_friendly_name']}
    end
    @nameMappings
  end

  #
  #
  #
  # API command:
  #               curl -H "X-API-KEY:<api_key>" -H "Accept: application/json" -F file=@<path_to_file> <host>/catalog/:id/annotations
  def upload_annotation
    uploaded_file = params[:file]
    id = params[:id]

    # Validate item
    item = Item.find_and_load_from_solr({id: id.to_s})
    if item.empty?
      respond_to do |format|
        format.json {
          render :json => {:error => "No Item with id '#{id}' exists."}.to_json, :status => 412
          return
        }
      end
    end
    item_handler = item.first[:handle].first

    if uploaded_file.blank? or uploaded_file.size == 0
      render :json => {:error => "Uploaded file is not present or empty."}.to_json, :status => 412
      return
    else

      # Here will validate that if the uploaded file is already in the system.
      # If we have a file with the same name, for the same item and with the same MD5 checksum will suppose that
      # that file was already uploaded, and hence will reject it.
      similarUploadedAnnotations = UserAnnotation.where(original_filename: uploaded_file.original_filename, item_identifier: item_handler)
      if (!similarUploadedAnnotations.empty?)
        currentFileContentMD5 = Digest::MD5.hexdigest(IO.read(uploaded_file.tempfile))

        similarUploadedAnnotations.each do |anUploadedAnnotations|
          existingFileMD5 = Digest::MD5.hexdigest(IO.read(anUploadedAnnotations.file_location))
          if(existingFileMD5.eql?(currentFileContentMD5))
            Rails.logger.debug("File already uploaded: Record id #{anUploadedAnnotations.id}.")
            render :json => {:error => "File already uploaded."}.to_json, :status => 412
            return
          end
        end
      end

      file_created = UserAnnotation.create_new_user_annotation(current_user, item_handler, uploaded_file)

      respond_to do |format|
        format.json {
          if file_created
            render :json => {:message => "file #{uploaded_file.original_filename} uploaded successfully"}.to_json, :status => 200
          else
            render :json => {:error => "Error uploading file #{uploaded_file.original_filename}."}.to_json, :status => 500
          end
        }
      end
    end
  end

  #
  #
  #
  # API command:
  #             curl -H "X-API-KEY:<key>" -H "Accept: application/json" <host>/catalog/download_annotation/<annotation_id>
  #def download_annotation
  #  begin
  #    userAnnotation = UserAnnotation.find(params[:id].to_i)
  #
  #    if (userAnnotation.nil?)
  #      raise Exception.new
  #    end
  #
  #    send_file userAnnotation.file_location,
  #              :filename => userAnnotation.original_filename,
  #              :type => userAnnotation.file_type
  #    return
  #  rescue => e
  #    Rails.logger.error(e.backtrace)
  #  end
  #  respond_to do |format|
  #    format.html {
  #      flash[:error] = "Sorry, you have requested an annotation that doesn't exist."
  #      redirect_to root_path and return
  #    }
  #    format.any { render :json => {:error => "not-found"}.to_json, :status => 404 }
  #  end
  #
  #end


  private

  #
  #
  #
  def processMetadataParameters(metadataSearchParam)
    # this regular expression should extract text like this
    #         word:word
    #         word:"word word"
    #         word:word~
    #
    searchPattern = /(\w+)\s*:\s*([^\s")]+(\s\S+")*|"[^"]*")/i
    matchingData = metadataSearchParam.to_enum(:scan, searchPattern).map {Regexp.last_match}

    matchingData.each { |m|
      key = m[1].to_s
      value = m[2].to_s

      queryFragments = []
      fieldsMappings = ItemMetadataFieldNameMapping.find_text_in_any_column(key)
      fieldsMappings.each do |anItemFieldMapping|
        solr_field_name = anItemFieldMapping.solr_name

        queryFragments << "#{solr_field_name}:#{value}"
      end

      if (!queryFragments.empty?)
        newQuery = "(#{queryFragments.join(" OR ")})"

        metadataSearchParam.sub!(m[0], newQuery)
      end

    }
    metadataSearchParam
  end

  #
  #
  #
  def download_as_zip(itemsId, file_name)
    begin
      bench_start = Time.now

      # Creates a ZIP file containing the documents and item's metadata
      zip_path = DownloadItemsAsArchive.new(current_user, current_ability).createAndRetrieveZipPath(itemsId) do |aDoc|
        @itemInfo = create_display_info_hash(aDoc)

        renderer = Rabl::Renderer.new('catalog/show', @itemInfo, { :format => 'json', :view_path => 'app/views', :scope => self })
        itemMetadata = renderer.render
        itemMetadata
      end

      # Sends the zipped file
      send_data IO.read(zip_path), :type => 'application/zip',
                :disposition => 'attachment',
                :filename => file_name

      Rails.logger.debug("Time for downloading metadata and documents for #{itemsId.length} items: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
      return

    rescue Exception => e
      Rails.logger.error(e.message + "\n " + e.backtrace.join("\n "))
    ensure
      # Ensure zipped file is removed
      FileUtils.rm zip_path if !zip_path.nil?
    end
    respond_to do |format|
      format.html {
        flash[:error] = "Sorry, an unexpected error occur."
        redirect_to @item_list and return
      }
      format.any { render :json => {:error => "Internal Server Error"}.to_json, :status => 500 }
    end
  end

  #
  # Add filter query when searching on metadata fields.
  #
  def add_metadata_extra_filters(solr_parameters, user_params)
    solr_parameters[:fq] << user_params[:fq]
  end

  #
  # Add unlimited rows when searching on metadata fields.
  #
  def add_unlimited_rows(solr_parameters, user_params)
    solr_parameters[:rows] = FIXNUM_MAX
  end

  #
  #
  #
  def wrapped_enforce_show_permissions(opts={})
    begin
      enforce_show_permissions(opts)
    rescue Hydra::AccessDenied => e
      respond_to do |format|
        format.html {raise e}
        format.any { render :json => {:error => "access-denied"}.to_json, :status => 403 }
      end
    rescue Blacklight::Exceptions::InvalidSolrID => e
      respond_to do |format|
        format.html {resource_not_found(Blacklight::Exceptions::InvalidSolrID.new("Sorry, you have requested a document that doesn't exist.")) and return}
        format.any { render :json => {:error => "not-found"}.to_json, :status => 404 }
      end
    end
  end

  #
  # query the annotations for an item and return them along with the "primary" document
  #
  def query_annotations(item, solr_document, type, label)
    uri = buildURI(item.id, 'annotationSet1')
    repo = RDF::Repository.load(uri, :format => :ttl)
    corpus = solr_document[MetadataHelper::short_form(MetadataHelper::COLLECTION)].first
    queryConfig = YAML.load_file(Rails.root.join("config", "sparql.yml"))

    q = "
      PREFIX dada:<http://purl.org/dada/schema/0.2#>
      PREFIX cp:<" + (queryConfig[corpus]['corpus_prefix'] unless queryConfig[corpus].nil?).to_s + ">
      select * where
      {
        ?anno a dada:Annotation .
        OPTIONAL { ?anno cp:val ?label . }
        OPTIONAL { ?anno dada:type ?type . }
        OPTIONAL {
          ?anno dada:targets ?loc .
          OPTIONAL { ?loc a ?region . }
          OPTIONAL { ?loc dada:start ?start . }
          OPTIONAL { ?loc dada:end ?end . }
        }
    "
    if type.present?
      q << "?anno dada:type '" + CGI.escape(type).to_s.strip + "' ."
    end
    if label.present?
      q << "?anno cp:val '" + CGI.escape(label).to_s.strip + "' ."
    end
    q << "}"

    query = SPARQL.parse(q)

    # hacky way to find the "primary" document, need to make this standard in RDF
    if !@item.primary_text.content.nil?
      annotates_document = "#{catalog_primary_text_url(@item.id, format: :json)}"
    else
      uris = [MetadataHelper::IDENTIFIER, MetadataHelper::TYPE, MetadataHelper::EXTENT, MetadataHelper::SOURCE]
      documents = item_documents(@document, uris)
      if(documents.present?)
        annotates_document = "#{catalog_document_url(@document.id, documents.first[MetadataHelper::IDENTIFIER])}"
      else
        annotates_document = "#{catalog_url(@item)}"
      end
    end

    return query.execute(repo), annotates_document
  end

  #
  # Returns an array of predefined vocabularies that should no be shown
  # in the json ld schema.
  #
  def collect_restricted_predefined_vocabulary
    avoid_context = []
    avoid_context << RDF::CC.to_uri
    avoid_context << RDF::CERT.to_uri
    avoid_context << RDF::DC11.to_uri
    avoid_context << RDF::DOAP.to_uri
    avoid_context << RDF::EXIF.to_uri
    avoid_context << RDF::GEO.to_uri
    avoid_context << RDF::GR.to_uri
    avoid_context << RDF::HCalendar.to_uri
    avoid_context << RDF::HCard.to_uri
    avoid_context << RDF::HTTP.to_uri
    avoid_context << RDF::ICAL.to_uri
    avoid_context << RDF::LOG.to_uri
    avoid_context << RDF::MA.to_uri
    avoid_context << RDF::MD.to_uri
    avoid_context << RDF::OG.to_uri
    avoid_context << RDF::OWL.to_uri
    avoid_context << RDF::PROV.to_uri
    avoid_context << RDF::PTR.to_uri
    avoid_context << RDF::RDFA.to_uri
    avoid_context << RDF::RDFS.to_uri
    avoid_context << RDF::REI.to_uri
    avoid_context << RDF::RSA.to_uri
    avoid_context << RDF::RSS.to_uri
    avoid_context << RDF::SIOC.to_uri
    avoid_context << RDF::SKOS.to_uri
    avoid_context << RDF::SKOSXL.to_uri
    avoid_context << RDF::V.to_uri
    avoid_context << RDF::VCARD.to_uri
    avoid_context << RDF::VOID.to_uri
    avoid_context << RDF::WDRS.to_uri
    avoid_context << RDF::WOT.to_uri
    avoid_context << RDF::XHTML.to_uri
    avoid_context << RDF::XHV.to_uri

    avoid_context << SPARQL::Grammar::SPARQL_GRAMMAR.to_uri

    avoid_context << "http://rdfs.org/sioc/types#"
    avoid_context
  end

end