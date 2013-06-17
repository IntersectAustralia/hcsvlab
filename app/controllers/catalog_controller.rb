# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class CatalogController < ApplicationController

  # Set catalog tab as current selected
  set_tab :catalog

  before_filter :authenticate_user!, :except => [:index]
  #load_and_authorize_resource

  include Blacklight::Catalog
  include Hydra::Controller::ControllerBehavior
  # These before_filters apply the hydra access controls
  #before_filter :enforce_show_permissions, :only=>:show
  # This applies appropriate access controls to all solr queries
  #CatalogController.solr_search_params_logic += [:add_access_controls_to_solr_params]
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

    config.add_facet_field 'DC_is_part_of', :label => 'Corpus', :limit => 2000, :partial => 'catalog/sorted_facet'
    config.add_facet_field 'date_group', :label => 'Created', :limit => 2000, :partial => 'catalog/sorted_facet'
    config.add_facet_field 'AUSNC_mode', :label => 'Mode', :limit => 2000, :partial => 'catalog/sorted_facet'
    config.add_facet_field 'AUSNC_speech_style', :label => 'Speech Style', :limit => 2000, :partial => 'catalog/sorted_facet'
    config.add_facet_field 'AUSNC_interactivity', :label => 'Interactivity', :limit => 2000, :partial => 'catalog/sorted_facet'
    config.add_facet_field 'AUSNC_communication_context', :label => 'Communication Context', :limit => 2000, :partial => 'catalog/sorted_facet' 
    config.add_facet_field 'AUSNC_audience', :label => 'Audience', :limit => 2000, :partial => 'catalog/sorted_facet' 
    config.add_facet_field 'OLAC_discourse_type', :label => 'Discourse Type', :limit => 2000, :partial => 'catalog/sorted_facet' 
    config.add_facet_field 'OLAC_language', :label => 'Language (ISO 639-3 Code)', :limit => 2000, :partial => 'catalog/sorted_facet'
    config.add_facet_field 'DC_type', :label => 'Type', :limit => 2000, :partial => 'catalog/sorted_facet'

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

    config.add_show_field solr_name('DC_title', :stored_searchable, type: :string), :label => 'Title:'
    config.add_show_field solr_name('DC_created', :stored_searchable, type: :string), :label => 'Created:'
    config.add_show_field solr_name('DC_identifier', :stored_searchable, type: :string), :label => 'Identifier:'
    config.add_show_field solr_name('DC_is_part_of', :stored_searchable, type: :string), :label => 'Corpus:'
    config.add_show_field solr_name('DC_Source', :stored_searchable, type: :string), :label => 'Source:'
    config.add_show_field solr_name('AUSNC_itemwordcount', :stored_searchable, type: :string), :label => 'Word Count'

    config.add_show_field solr_name('AUSNC_mode', :stored_searchable, type: :string), :label => 'Mode:'
    config.add_show_field solr_name('AUSNC_speech_style', :stored_searchable), :label => 'Speech Style:' 
    config.add_show_field solr_name('AUSNC_interactivity', :stored_searchable), :label => 'Interactivity:' 
    config.add_show_field solr_name('AUSNC_communication_context', :stored_searchable), :label => 'Communication Context:' 
    config.add_show_field solr_name('AUSNC_discourse_type', :stored_searchable), :label => 'Discourse Type:' 
    config.add_show_field solr_name('OLAC_discourse_type', :stored_searchable), :label => 'Discourse Type:' 
    config.add_show_field solr_name('OLAC_language', :stored_searchable), :label => 'Language (ISO 639-3 Code):' 

    config.add_show_field solr_name('ACE_genre', :stored_searchable, type: :string), :label => 'Genre:'
    config.add_show_field solr_name('AUSNC_audience', :stored_searchable, type: :string), :label => 'Audience:'
    config.add_show_field solr_name('AUSNC_communication_setting', :stored_searchable, type: :string), :label => 'Communication Setting:'
    config.add_show_field solr_name('AUSNC_plaintextversion', :stored_searchable, type: :string), :label => 'Plain Text:'
    config.add_show_field solr_name('AUSNC_publication_status', :stored_searchable, type: :string), :label => 'Publication Status:'
    config.add_show_field solr_name('AUSNC_source', :stored_searchable, type: :string), :label => 'Source:'
    config.add_show_field solr_name('AUSNC_written_mode', :stored_searchable, type: :string), :label => 'Written Mode:'
    config.add_show_field solr_name('DC_contributor', :stored_searchable, type: :string), :label => 'Contributor:'
    config.add_show_field solr_name('DC_publisher', :stored_searchable, type: :string), :label => 'Publisher:'

    config.add_show_field solr_name('AUSNC_document', :stored_searchable, type: :string), :label => 'Documents:'
    config.add_show_field solr_name('DC_type', :stored_searchable, type: :string), :label => 'Type:'
    config.add_show_field solr_name('DC_extent', :stored_searchable, type: :string), :label => 'Extent:'
    config.add_show_field solr_name('Item', :stored_searchable, type: :string), :label => 'Item:'

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



end 
