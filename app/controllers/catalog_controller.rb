# -*- encoding : utf-8 -*-
require 'blacklight/catalog'
require 'yaml'
require "#{Rails.root}/lib/item/download_items_helper.rb"
require 'net/http'
require 'uri'

class CatalogController < ApplicationController

  FIXNUM_MAX = 2147483647
  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG

  TYPE_LOOKUP = {"SecondRegion" => "SecondAnnotation", "UTF8Region" => "TextAnnotation"}

  # Set catalog tab as current selected
  set_tab :catalog

  before_filter :authenticate_user!, :except => [:index, :annotation_context, :searchable_fields]

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::CatalogHelperBehavior

  include Item::DownloadItemsHelper
  include ERB::Util

  prepend_before_filter :retrieve_and_set_item_id

  # These before_filters apply the hydra access controls
  before_filter :wrapped_enforce_show_permissions, :only => [:show, :document, :primary_text, :annotations, :upload_annotation]
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
    config.add_show_field 'collection_name_facet', :label => 'Collection'
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

    if current_user
      begin
        if params[:q].present? or params[:f].present? or params[:metadata].present?
          search = UserSearch.new(:search_time => Time.now, :search_type => SearchType::MAIN_SEARCH)
          search.user = current_user
          search.save
        end
        metadataSearchParam = params[:metadata]
        if !metadataSearchParam.nil? and !metadataSearchParam.empty?
          if metadataSearchParam.include?(":")
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
        @hasAccessToEveryCollection = true
        @hasAccessToSomeCollections = false
        #TODO REFACTOR
        Collection.all.each do |aCollection|
          #I have access to a collection if I am the owner or if I accepted the licence for that collection
          hasAccessToCollection = (aCollection.flat_ownerEmail.eql? current_user.email) ||
              (current_user.has_agreement_to_collection?(aCollection, UserLicenceAgreement::DISCOVER_ACCESS_TYPE, false))

          @hasAccessToSomeCollections = @hasAccessToSomeCollections || hasAccessToCollection
          @hasAccessToEveryCollection = @hasAccessToEveryCollection && hasAccessToCollection
        end
      rescue Errno::ECONNREFUSED => e
        Rails.logger.debug(e.message)
        Rails.logger.debug(e.backtrace)
        raw_data = {
            :exception => e,
            :rack_env => env
        }
        WhoopsLogger.log(:rails_exception, raw_data) if WhoopsLogger.config.host
        redirect_to new_issue_report_path, alert: "Solr is experiencing problems at the moment. The administrators have been informed of the issue."
      rescue RSolr::Error::Http => e
        Rails.logger.debug(e.message)
        Rails.logger.debug(e.backtrace)
        flash[:error] = "Sorry, error in search parameters."
      end
    else
      respond_to do |format|
        format.json { render :nothing => true, :status => 406 }
        format.html {}
      end
    end
  end

  #
  #
  #
  def advanced_search

  end

  #
  #
  #
  def advanced_search_syntax

  end

  #
  # override default show method to allow for json response
  #
  def show
    if Item.where(id: params[:id]).count != 0
      @response, @document = get_solr_response_for_doc_id

      # For some reason blacklight stopped to fullfill the counter value in the session since we changed
      # the item url to use /catalog/:collection/:itemId. So will set this in here.
      session[:search][:counter] = params[:counter] if params[:counter].present?

      @display_document = get_display_document(@document)

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

  #
  #
  #
  def search
    request.format = 'json'
    search = UserSearch.new(:search_time => Time.now, :search_type => SearchType::MAIN_SEARCH)
    search.user = current_user
    search.save
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

  #
  #
  #
  def annotations
    bench_start = Time.now
    @item = Item.find(params[:id])
    if @item
      @response, @document = get_solr_response_for_doc_id
    end
    begin

      if @item.annotation_path.present?
        begin
          @anns, @annotates_document = query_annotations(@item, @document, params[:type], params[:label])
        rescue Exception => e
          Rails.logger.error(e.message)
          Rails.logger.error(e.backtrace.join("\n"))
          respond_to do |format|
            format.json { render :json => {:error => "error in query parameters"}.to_json, :status => 400 }
          end
        end

        respond_to do |format|
          format.json {}
        end
        return
      end
    rescue Exception => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      # Fall through to return Not Found
    end
    respond_to do |format|
      format.json { render :json => {:error => "not-found"}.to_json, :status => 404 }
    end
    bench_end = Time.now
    Rails.logger.debug("Time for retrieving annotations for #{params[:id]} took: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
  end

  #
  #
  #
  def annotation_properties
    begin
      @item = Item.find(params[:id])

      if @item.annotation_path.present?
        @properties = query_annotation_properties(@item)

        respond_to do |format|
          format.json {}
        end
        return
      end
    rescue Exception => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      # Fall through to return Not Found
    end
    respond_to do |format|
      format.json { render :json => {:error => "not-found"}.to_json, :status => 404 }
    end
  end

  #
  #
  #
  def annotation_types
    begin
      @item = Item.find(params[:id])

      if @item.annotation_path.present?

        @types = query_annotation_types(@item)

        respond_to do |format|
          format.json {}
        end
        return
      end
    rescue Exception => e
      Rails.logger.error(e.message)
      Rails.logger.error(e.backtrace.join("\n"))
      # Fall through to return Not Found
    end
    respond_to do |format|
      format.json { render :json => {:error => "not-found"}.to_json, :status => 404 }
    end
  end

  #
  #
  #
  def annotation_context
    @predefinedProperties = collect_predefined_context_properties

    avoid_context = collect_restricted_predefined_vocabulary

    @vocab_hash = {}
    RDF::Vocabulary.each { |vocab|
      if !avoid_context.include?(vocab.to_uri) and vocab.to_uri.qname.present?
        prefix = vocab.to_uri.qname.first.to_s
        uri = vocab.to_uri.to_s
        @vocab_hash[prefix] = {:@id => uri}
      end
    }
    request.format = 'json'
    respond_to 'json'

  end

  #
  #
  #
  def primary_text
    bench_start = Time.now
    begin
      item = Item.find(params[:id])

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

  #
  #
  #
  def document
    begin
      doc = Document.find_by_file_name_and_item_id(params[:filename], params[:id])

      if doc.present?
        params[:disposition] = 'Inline'
        params[:disposition].capitalize!

        # If HTTP_RANGE variable is set, we need to send partial content and tell the browser
        # what fragment of the file we are sending by using the variables Content-Range and
        # Content-Length
        if request.headers["HTTP_RANGE"]
          #TODO how to send file with partial content?
          size = doc.datastreams['CONTENT1'].content.size
          bytes = Rack::Utils.byte_ranges(request.headers, size)[0]
          offset = bytes.begin
          length = bytes.end - bytes.begin

          response.header["Accept-Ranges"] = "bytes" # Tells the browser that we accept partial content
          response.header["Content-Range"] = "bytes #{bytes.begin}-#{bytes.end}/#{size}"
          response.header["Content-Length"] = (length+1).to_s
          response.status = :partial_content

          #TODO content?
          # content = doc.datastreams['CONTENT1'].content[offset, length+1]
        else
          #TODO content?
          # content = doc.datastreams['CONTENT1'].content
          response.header["Content-Length"] = Rack::Utils.bytesize(content).to_s

        end
        send_file doc.file_path, disposition: params[:disposition], type: doc.mime_type
        # send_data content,
        #           :disposition => params[:disposition],
        #           :filename => doc.file_name[0].to_s,
        #           :type => doc.datastreams['CONTENT1'].mimeType.to_s

        return
      end
    rescue Exception => e
      Rails.logger.error(e.backtrace)
      # Fall through to return Not Found
    end
    respond_to do |format|
      #format.html { raise ActionController::RoutingError.new('Not Found') }
      format.html { flash[:error] = "Sorry, you have requested a document that doesn't exist."
      redirect_to catalog_path(params[:id]) and return }
      format.any { render :json => {:error => "not-found"}.to_json, :status => 404 }
    end
  end

  #
  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
  #
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

      itemHandles = params[:items].collect { |x| "#{File.basename(File.split(x).first)}:#{File.basename(x)}" }

      respond_to do |format|
        format.warc {
          download_as_warc(itemHandles, "items.warc")
        }
        format.any {
          download_as_zip(itemHandles, "items.zip")
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
    @nameMappings.sort! { |x, y| x[:user_friendly_name].downcase <=> y[:user_friendly_name].downcase }
    @nameMappings
  end

  #
  # API command:
  #               curl -H "X-API-KEY:<api_key>" -H "Accept: application/json" -F file=@<path_to_file> <host>/catalog/:collection/:itemId/annotations
  def upload_annotation
    uploaded_file = params[:file]
    item_handler = "#{params[:collection]}:#{params[:itemId]}"

    # Validate item. This line will also validate that the user has permission for adding
    # the annotation in that item.
    item = Item.find_by_handle(item_handler)
    if item.empty?
      respond_to do |format|
        format.json {
          render :json => {:error => "No Item with handle '#{item_handler}' exists."}.to_json, :status => 412
          return
        }
      end
    end

    if !uploaded_file.is_a? ActionDispatch::Http::UploadedFile
      render :json => {:error => "Error in file parameter."}.to_json, :status => 412
      return
    elsif uploaded_file.blank? or uploaded_file.size == 0
      render :json => {:error => "Uploaded file is not present or empty."}.to_json, :status => 412
      return
    else

      # Here will validate that if the uploaded file is already in the system.
      # If we have a file with the same name, for the same item and with the same MD5 checksum will suppose that
      # that file was already uploaded, and hence will reject it.
      similarUploadedAnnotations = UserAnnotation.where(original_filename: uploaded_file.original_filename, item_identifier: item_handler)
      if !similarUploadedAnnotations.empty?
        currentFileContentMD5 = Digest::MD5.hexdigest(IO.read(uploaded_file.tempfile))

        similarUploadedAnnotations.each do |anUploadedAnnotations|
          existingFileMD5 = Digest::MD5.hexdigest(IO.read(anUploadedAnnotations.file_location))
          if (existingFileMD5.eql?(currentFileContentMD5))
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
            render :json => {:success => "file #{uploaded_file.original_filename} uploaded successfully"}.to_json, :status => 200
          else
            render :json => {:error => "Error uploading file #{uploaded_file.original_filename}."}.to_json, :status => 500
          end
        }
      end
    end
  end

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

  #
  # This method expose the triple store endpoint. Previous sending the request to sesame
  # we validate that the user has read access to the collection.
  #
  def sparqlQuery
    request.format = 'json'

    search = UserSearch.new(:search_time => Time.now, :search_type => SearchType::TRIPLESTORE_SEARCH)
    search.user = current_user
    search.save

    # First will validate the parameters. 'collection' and 'query' are both required
    query = params[:query]
    collection_name = params[:collection].to_s.downcase

    # If the 'query' parameter is no present then we return precondition no met error.
    if query.blank?
      respond_to do |format|
        format.json { render :json => {:error => "Parameter 'query' is required."}.to_json, :status => 412 and return }
      end
    end

    # Now we are going to forbid the SERVICE keyword in the SPARQL query
    pattern = /SERVICE/i
    matchingWords = query.to_enum(:scan, pattern).map { Regexp.last_match }
    if matchingWords.present?
      respond_to do |format|
        format.json { render :json => {:error => "Service keyword is forbidden in queries."}.to_json, :status => 412 and return }
      end
    end

    collection = Collection.find_by_name(collection_name)
    if collection.nil?
      respond_to do |format|
        format.json { render :json => {:error => "collection not-found"}.to_json, :status => 404 and return }
      end
    end

    if collection.present?
      #Verify if the user has at least read access to the collection
      if !(current_user.has_agreement_to_collection?(collection, UserLicenceAgreement::READ_ACCESS_TYPE, false))
        authorization_error(Exception.new("You are not authorized to access this resource."))
        return
      end
    end

    #
    # I'll leave this code commented out since in the future we might have to include the
    # SERVICE keyword and we'll have to validate that.
    #

    # In a sparql query the user can specify the keyword SERVICE in order
    # to make a query in a particular repository.
    # We need to parse those type of query and validate that the user
    # has read access to those specified repositories.
    #
    # Regex will match: SERVICE [SILENT] <HOST_URL>/repositories/<repo_name>
    #pattern = /SERVICE\s+(?:.*\s+)?<#{SESAME_CONFIG["url"]}\/repositories\/(\w+)>/i
    #matchingWords = query.to_enum(:scan, pattern).map { Regexp.last_match }

    # At this point we will collect
    #collectionNames = []
    #collectionNames << {name:collectionName, silent:false} if collectionName.present?
    #matchingWords.each do |aMatching|
    #  isSilent = !aMatching[0].to_s.match(/SERVICE\s+SILENT/i).nil?
    #  collectionNames << {name: aMatching[1], silent:isSilent}
    #end

    #if (collectionNames.empty?)
    #  respond_to do |format|
    #    format.json { render :json => {:error => "Parameter 'collection' or SERVICE keyword in query is required."}.to_json, :status => 412 and return}
    #  end
    #end

    #collections = []
    #collectionNames.each do |aCollectionName|
    #  Retrieve the collection from Fedora
    #collection = Collection.find_by_short_name(aCollectionName[:name]).to_a.first
    #if (collection.nil? && !aCollectionName[:silent])
    #  respond_to do |format|
    #    format.json { render :json => {:error => "collection not-found"}.to_json, :status => 404 and return}
    #  end
    #end
    #
    #if (!collection.nil?)
    #  Verify if the user has at least read access to the collection
    #if !(current_user.has_agreement_to_collection?(collection, UserLicenceAgreement::READ_ACCESS_TYPE, false))
    #  authorization_error(Exception.new("You are not authorized to access this resource."))
    #  return
    #end
    #collections << collection
    #end
    #end

    # Create the URL for the sesame endpoint.
    params = {query: query}
    uri = URI("#{SESAME_CONFIG["url"]}/repositories/#{collection_name}")
    uri.query = URI.encode_www_form(params)

    # Send the request to the sparql endpoint.
    req = Net::HTTP::Get.new(uri)
    req.add_field("accept", "application/json")
    res = Net::HTTP.new(uri.host, uri.port).start do |http|
      http.request(req)
    end

    # If sesame returns an error, then we show the error received by sesame
    if (!res.is_a?(Net::HTTPSuccess))
      respond_to do |format|
        format.json { render :json => {:error => res.body}.to_json, :status => res.code and return }
      end
    else
      # Otherwise we send the response as json format.
      respond_to do |format|
        format.json { render :json => res.body.to_s and return }
      end
    end
  end

  private

  #
  #
  #
  def processMetadataParameters(metadataSearchParam)
    # this regular expression should extract text like this
    #         word:word
    #         word:"word word"
    #         word:word~
    #         word
    searchPattern = /(\w+)\s*:\s*([^\s")]+(\s\S+")*|"[^"]*")|(\w+)/i
    matchingData = metadataSearchParam.to_enum(:scan, searchPattern).map { Regexp.last_match }

    matchingData.each { |m|
      if (m.to_s.include?(':'))
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
      elsif ('AND'!=m.to_s and 'OR'!=m.to_s)
        newQuery = "all_metadata:#{m[0].to_s}"
        metadataSearchParam.sub!(m[0], newQuery)
      end
    }
    metadataSearchParam
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
  # This method will collect the :collection and :itemId parameters and will try to obtain the
  # sequential identifier.
  #
  def retrieve_and_set_item_id
    handle = nil
    handle = "#{params[:collection]}:#{params[:itemId]}" if params[:collection].present? and params[:itemId].present?

    if handle.present?
      item = Item.find_by_handle(handle)
      if item.nil?
        respond_to do |format|
          format.html { resource_not_found(Blacklight::Exceptions::InvalidSolrID.new("Sorry, you have requested a document that doesn't exist.")) and return }
          format.any { render :json => {:error => "not-found"}.to_json, :status => 404 and return }
        end
      end
      params[:id] = item.first.id if item.present?
    end
  end

  #
  #
  #
  def wrapped_enforce_show_permissions(opts={})
    begin
      enforce_show_permissions(opts)
    rescue Hydra::AccessDenied => e
      respond_to do |format|
        format.html { raise e }
        format.any { render :json => {:error => "access-denied"}.to_json, :status => 403 }
      end
    rescue Blacklight::Exceptions::InvalidSolrID => e
      respond_to do |format|
        format.html { resource_not_found(Blacklight::Exceptions::InvalidSolrID.new("Sorry, you have requested a document that doesn't exist.")) and return }
        format.any { render :json => {:error => "not-found"}.to_json, :status => 404 }
      end
    end
  end

  #
  # query the annotations for an item and return them along with the "primary" document
  #
  def query_annotations(item, solr_document, type, label)
    item_short_identifier = item.handle.split(":").last
    corpus = item.collection.flat_name

    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
    repo = server.repository(corpus)

    namespaces = RdfNamespace.get_namespaces(item.collection.flat_name)

    prefixes = ""
    namespaces.each do |k, v|
      prefixes << "PREFIX #{k}:<#{v}>\n"
    end

    filters = ""
    user_params.each do |key, value|
      # key must be a uri, if it is add filter to query
      unless literal_sparql_key(key)
        filters << "FILTER( EXISTS { ?anno #{sparql_item(key)} #{sparql_item(value)} } || EXISTS { ?loc #{sparql_item(key)} #{sparql_item(value)} } "
        # If searching for non-uri term, we need to search for terms both inclosed in quotes and without
        filters << "|| EXISTS { ?anno #{sparql_item(key)} #{sparql_item(value)} } || EXISTS { ?loc #{sparql_item(key)} #{sparql_item(value)} } ".gsub("'", "") if literal_sparql_key(value)
        filters << ")\n"
      else
        Rails.logger.error("Invalid sparql query subject, must be a URI")
        raise Exception.new
      end
    end

    type_and_label = ""
    if type.present?
      type_and_label << "?anno dada:type #{sparql_item(type.to_s.strip)} .\n"
    end
    if label.present?
      type_and_label << "?anno dada:label #{sparql_item(label.to_s.strip)} .\n"
    end

    query = "" "
    #{prefixes}
      SELECT *
      WHERE {
        ?identifier dc:identifier '#{item_short_identifier}'.
        ?annoCol dada:annotates ?identifier .
        ?anno dada:partof ?annoCol .
        ?anno a dada:Annotation .
        #{type_and_label}
        OPTIONAL { ?anno dada:label ?label . }
        OPTIONAL { ?anno dada:type ?type . }
        OPTIONAL {
          ?anno dada:targets ?loc .
          OPTIONAL { ?loc ?property ?value . }
        }
        #{filters unless filters.empty?}
      }
    " ""

    solution = repo.sparql_query(query)

    hash = {}
    commonProperties = {}

    # Look for properties defined in the project's Json-LD
    predefinedProperties = collect_predefined_context_properties()
    predefinedPropertiesMap = {}
    predefinedProperties.map { |key, value|
      if (value.is_a?(String))
        predefinedPropertiesMap[value] = key
      else
        predefinedPropertiesMap[value[:@id].to_s] = key
      end
    }

    solution.each do |aSolution|

      hash[aSolution[:anno].to_s] = {} if (hash[aSolution[:anno].to_s].nil?)

      hash[aSolution[:anno].to_s][:label] = aSolution[:label].to_s unless aSolution[:label].nil?
      hash[aSolution[:anno].to_s][:type] = aSolution[:type].to_s unless aSolution[:type].nil?

      if (RDF.type.to_s.eql? (aSolution[:property].to_s))
        type = RdfNamespace.get_shortened_uri(aSolution[:value].to_s, namespaces)
        TYPE_LOOKUP.keys.each do |k|
          if type.include? k
            type = type.sub(k, TYPE_LOOKUP[k])
          end
        end
        hash[aSolution[:anno].to_s][:@type] = type
      else
        # If the property URI is predefined in our Json-ld, then we should use the short_name of the URI
        if (predefinedPropertiesMap.has_key?(aSolution[:property].to_s))
          hash[aSolution[:anno].to_s][predefinedPropertiesMap[aSolution[:property].to_s]] = aSolution[:value].to_s
        else
          hash[aSolution[:anno].to_s][aSolution[:property].to_s] = aSolution[:value].to_s
        end
      end
    end

    display_document = get_display_document(solr_document)

    if !display_document.nil?
      annotates_document = catalog_document_url(@item.collection.flat_name, filename: display_document[:id])
    else
      annotates_document = catalog_url(@item.collection.flat_name, item_short_identifier)
    end

    return {commonProperties: commonProperties, annotations: hash}, annotates_document
  end

  #
  # Gets a list of annotation types for the give item
  #
  def query_annotation_types(item)
    types = []
    item_short_identifier = item.handle.split(":").last

    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
    repo = server.repository(item.collection.flat_name)

    query = "" "
        PREFIX dada:<http://purl.org/dada/schema/0.2#>
        PREFIX dc: <http://purl.org/dc/terms/>
        SELECT *
        WHERE {
            ?identifier dc:identifier '#{item_short_identifier}'.
            ?annoCol dada:annotates ?identifier .
            ?anno dada:partof ?annoCol .
            ?anno a dada:Annotation .
            ?anno dada:type ?type .
        }
    " ""

    sols = repo.sparql_query(query)
    sols = sols.select(:type).distinct

    sols.each do |sol|
      types.push(sol[:type].to_s)
    end
    types
  end

  #
  # Gets a list of annotation properties for the give item
  #
  def query_annotation_properties(item)
    properties = []
    item_short_identifier = item.handle.split(":").last

    server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
    repo = server.repository(item.collection.flat_name)

    query = "" "
        PREFIX dada:<http://purl.org/dada/schema/0.2#>
        PREFIX dc: <http://purl.org/dc/terms/>
        SELECT ?property
        WHERE { 
            {
                ?identifier dc:identifier '#{item_short_identifier}'.
                ?annoCol dada:annotates ?identifier .
                ?anno dada:partof ?annoCol .
                ?anno a dada:Annotation .
                ?anno ?property ?value .
            }
            UNION {
                ?identifier dc:identifier '#{item_short_identifier}'.
                ?annoCol dada:annotates ?identifier .
                ?anno dada:partof ?annoCol .
                ?anno a dada:Annotation .
                ?anno dada:targets ?loc .
                ?loc ?property ?value .
            }
        }
    " ""

    sols = repo.sparql_query(query)
    props = sols.select(:property).distinct

    namespaces = RdfNamespace.get_namespaces(item.collection.flat_name)
    props.each do |sol|
      entry = {:uri => sol[:property].to_s}
      entry[:shortened_uri] = RdfNamespace.get_shortened_uri(sol[:property].to_s, namespaces) if RdfNamespace.get_shortened_uri(sol[:property].to_s, namespaces) != entry[:uri]
      properties.push(entry)
    end
    properties
  end

  #
  # Get the display document for an item as a hash with id, type and source
  #
  def get_display_document(document)
    item = Item.find(document[:id])

    begin
      server = RDF::Sesame::HcsvlabServer.new(SESAME_CONFIG["url"].to_s)
      repository = server.repository(item.collection.flat_name)

      query = RDF::Query.new do
        pattern [RDF::URI.new(item.uri), MetadataHelper::DISPLAY_DOCUMENT, :display_doc]
        pattern [:display_doc, MetadataHelper::TYPE, :type]
        pattern [:display_doc, MetadataHelper::SOURCE, :source]
        pattern [:display_doc, MetadataHelper::IDENTIFIER, :id]
      end

      results = repository.query(query)

      results.each do |res|
        return {:id => res[:id].value, :type => res[:type].value, :source => res[:source].value}
      end

    rescue => e
      Rails.logger.error e.inspect
      Rails.logger.error "Could not connect to triplestore - #{SESAME_CONFIG["url"].to_s}"
    end
    return nil
  end

  #
  #
  #
  def collect_predefined_context_properties
    predefinedProperties = {}
    predefinedProperties[:commonProperties] = {:@id => "http://purl.org/dada/schema/0.2#commonProperties"}
    predefinedProperties[:dada] = {:@id => "http://purl.org/dada/schema/0.2#"}
    predefinedProperties[:type] = {:@id => "http://purl.org/dada/schema/0.2#type"}
    predefinedProperties[:start] = {:@id => "http://purl.org/dada/schema/0.2#start"}
    predefinedProperties[:end] = {:@id => "http://purl.org/dada/schema/0.2#end"}
    predefinedProperties[:label] = {:@id => "http://purl.org/dada/schema/0.2#label"}
    predefinedProperties[:"#{PROJECT_PREFIX_NAME}"] = {:@id => "#{PROJECT_SCHEMA_LOCATION}"}

    predefinedProperties
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

  def user_params
    return params.except(:format, :action, :controller, :id, :collection, :itemId, :type, :label, :api_key)
  end

  def sparql_item(item)
    if uri? item
      return "<#{item}>"
    elsif item.include? ":"
      return item
    else
      return "'#{item}'"
    end
  end

  def literal_sparql_key(item)
    if uri? item or item.include? ":"
      return false
    end
    return true
  end

  def uri?(string)
    uri = URI.parse(string)
    %w( http https ).include?(uri.scheme)
  rescue URI::BadURIError
    false
  rescue URI::InvalidURIError
    false
  end

end