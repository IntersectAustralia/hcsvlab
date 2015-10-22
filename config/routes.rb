HcsvlabWeb::Application.routes.draw do
  # This constraint specify that we are going to accept any character except '/' for an item id.
  catalogRoutesConstraints = {:itemId => /[^\/]+/}
  catalogRoutesConstraintsIncludingJson = {:itemId => /(?:(?!\.json|\/).)+/i}

  root :to => "catalog#index"

  get "version", :to => "application#version"
  get "metrics", :to => 'application#metrics', :as => 'view_metrics'
  get "metrics/download", :to => 'application#metrics_download', :as => 'download_metrics'

  get "/", :to => 'catalog#index', :as => 'catalog_index'
  get "catalog/advanced_search", :to => 'catalog#advanced_search', :as => 'catalog_advanced_search'
  get "catalog/searchable_fields", :to => 'catalog#searchable_fields', :as => 'catalog_searchable_fields'
  get "catalog/search", :to => 'catalog#search', :as => 'catalog_search'
  get 'sparql/:collection', :to => 'catalog#sparqlQuery', :as => 'catalog_sparqlQuery'

  # :show and :update are for backwards-compatibility with catalog_url named routes
  get 'catalog/:collection/:itemId', :to => 'catalog#show', :as => "catalog", :constraints => catalogRoutesConstraintsIncludingJson
  # put 'catalog/:collection/:itemId', :to => 'catalog#update', :as => "catalog", :constraints => catalogRoutesConstraintsIncludingJson
  get 'catalog/:collection/:itemId', :to => 'catalog#show', :as => "solr_document", :constraints => catalogRoutesConstraintsIncludingJson
  # put 'catalog/:collection/:itemId', :to => 'catalog#update', :as => "solr_document", :constraints => catalogRoutesConstraintsIncludingJson

  # Collection definitions
  get "catalog", :to => 'collections#index', :as => 'collections'
  get "catalog/:id", :to => 'collections#show', :as => 'collection'
  put "catalog/:id", :to => 'collections#edit_collection', :as => 'collection'
  post "catalog", :to => 'collections#create', :as => 'collections'
  delete "catalog/:collectionId/:itemId",:to => 'collections#delete_item_from_collection', :as => 'delete_collection_item', :constraints => catalogRoutesConstraintsIncludingJson
  put "catalog/:collectionId/:itemId", :to => 'collections#update_item', :as => 'update_collection_item', :constraints => catalogRoutesConstraints
  post "catalog/:collectionId/:itemId", :to => 'collections#add_document_to_item', :as => 'add_item_document', :constraints => catalogRoutesConstraints
  delete "catalog/:collectionId/:itemId/document/:filename", :to => 'collections#delete_document_from_item', :as => 'delete_item_document', :filename => /.*/, :constraints => catalogRoutesConstraints

  get 'catalog/:collectionId/:itemId/delete', :to => 'collections#delete_item_via_web_app', :as => "delete_item_web", :constraints => catalogRoutesConstraintsIncludingJson

  # In /config/initializers/blacklight_routes.rb we are overriding one of the methods of this class
  Blacklight::Routes.new(self, :except => [:solr_document]).draw


  get "catalog/:collection/:itemId/primary_text", :to => 'catalog#primary_text', :as => 'catalog_primary_text', :constraints => catalogRoutesConstraints
  get "catalog/:collection/:itemId/document/:filename", :to => 'catalog#document', :as => 'catalog_document', :format => false, :filename => /.*/, :constraints => catalogRoutesConstraints
  get "catalog/:collection/:itemId/document/", :to => 'catalog#document', :as => 'catalog_document_api', :constraints => catalogRoutesConstraints
  get "catalog/:collection/:itemId/annotations", :to => 'catalog#annotations', :as => 'catalog_annotations', :constraints => catalogRoutesConstraints
  post 'catalog/:collection/:itemId/annotations', :to => 'catalog#upload_annotation', :constraints => catalogRoutesConstraints
  get "catalog/:collection/:itemId/annotations/properties", :to => 'catalog#annotation_properties', :as => 'catalog_annotation_properties', :constraints => catalogRoutesConstraints
  get "catalog/:collection/:itemId/annotations/types", :to => 'catalog#annotation_types', :as => 'catalog_annotation_types', :constraints => catalogRoutesConstraints

  post 'catalog/download_items', :to => 'catalog#download_items', :as => 'catalog_download_items_api'
  #get 'catalog/download_annotation/:id', :to => 'catalog#download_annotation', :as => 'catalog_download_annotation'

  post "catalog/:id", :to => 'collections#add_items_to_collection', :as => 'collection'

  HydraHead.add_routes(self)

  devise_for :users, controllers: {registrations: "user_registers", passwords: "user_passwords"}

  devise_scope :user do
    get "/users/aaf_sign_in", :to => "devise/sessions#aaf_new"
    get "/account/", :to => "user_registers#index" #allow users to edit their own password
    get "/account/edit", :to => "user_registers#edit" #allow users to edit their own password
    get "/account/edit_password", :to => "user_registers#edit_password" #allow users to edit their own password
    get "/account/licence_agreements", :to => "user_registers#licence_agreements" #allow users to edit their own password
    put "/account/update_password", :to => "user_registers#update_password" #allow users to edit their own password
    get "/account/generate_token", :to => "user_registers#generate_token" #allow users to generate an API token
    get "/account_api_key", :to => "user_registers#download_token"
    delete "/account/delete_token", :to => "user_registers#delete_token" #allow users to delete their API token
    delete "/account/licence_agreements/:id/cancel_request", :to => "user_licence_requests#cancel_request", :as => 'cancel_request'
  end

  resources :item_lists, :only => [:index, :show, :create, :update, :destroy] do
      collection do
        post 'add_items'
      end

      member do
        post 'clear'
        get 'concordance_search'
        get 'frequency_search'
        get 'download_config_file'
        get 'download_item_list'
        post 'share'
        post 'unshare'
        post 'aspera_transfer_spec'
      end
  end

  # resources :media_items, :transcripts
  match '/eopas/:collection/:itemId' => 'transcripts#show', :as => 'eopas', :constraints => catalogRoutesConstraints

  match 'schema/json-ld' => 'catalog#annotation_context', :as => 'annotation_context'
  resources :issue_reports, :only => [:new, :create] do
  end

  get "document_audit", :to => 'admin#document_audit', :as => 'document_audit'
  get "document_audit/download", :to => 'admin#document_audit_download', :as => 'download_document_audit'

  resources :admin, :only => [:index] do
    collection do

      resources :users, :only => [:index, :show], :path => "/users" do
        collection do
          get :access_requests
          get :index
          get :admin
          post :accept_licence_terms
          post :send_licence_request
        end
        member do
          put :reject
          put :reject_as_spam
          put :deactivate
          put :activate
          get :edit_role
          put :update_role
          get :edit_approval
          put :approve
        end
      end

      resources :collections, :only => [:new, :create], :path => "/collections" do
        collection do
          post 'add_licence_to_collection'
          put 'change_collection_privacy'
          put 'revoke_access'
        end
      end

      resources :collection_lists, :only => [:index, :show, :new, :create, :destroy] do
        collection do
          post 'add_collections'
          post 'add_licence_to_collection_list'
          get 'remove_collection'
          put 'change_collection_list_privacy'
          put 'revoke_access'
        end
      end

      resources :licences, :only => [:index, :new, :create], :path => "/licences" do
        get :index
      end

      resources :user_licence_requests, :only => [:index], :path => "/collection_requests" do
        member do
          put :approve_request
          put :reject_request
        end
      end


    end
  end
end
