HcsvlabWeb::Application.routes.draw do
  root :to => "catalog#index"

  get "version", :to => "application#version"

  get "catalog/search", :to => 'catalog#search', :as => 'catalog_search'
  get "catalog/searchable_fields", :to => 'catalog#searchable_fields', :as => 'searchable_fields'

  Blacklight.add_routes(self)
  get "catalog/:id/primary_text", :to => 'catalog#primary_text', :as => 'catalog_primary_text'
  get "catalog/:id/document/:filename", :to => 'catalog#document', :as => 'catalog_document', :format => false, :filename => /.*/
  get "catalog/:id/document/", :to => 'catalog#document', :as => 'catalog_document_api'
  get "catalog/:id/annotations", :to => 'catalog#annotations', :as => 'catalog_annotations'
  post 'catalog/:id/annotations', :to => 'catalog#upload_annotation'

  post 'catalog/download_items', :to => 'catalog#download_items', :as => 'catalog_download_items_api'
  #get 'catalog/download_annotation/:id', :to => 'catalog#download_annotation', :as => 'catalog_download_annotation'

  HydraHead.add_routes(self)
  
  devise_for :users, controllers: {registrations: "user_registers", passwords: "user_passwords"}

  devise_scope :user do
    get "/account/", :to => "user_registers#index" #allow users to edit their own password
    get "/account/edit", :to => "user_registers#edit" #allow users to edit their own password
    get "/account/edit_password", :to => "user_registers#edit_password" #allow users to edit their own password
    get "/account/licence_agreements", :to => "user_registers#licence_agreements" #allow users to edit their own password
    put "/account/update_password", :to => "user_registers#update_password" #allow users to edit their own password
    put "/account/generate_token", :to => "user_registers#generate_token" #allow users to generate an API token
    get "/account_api_key", :to => "user_registers#download_token"
    delete "/account/delete_token", :to => "user_registers#delete_token" #allow users to delete their API token
    delete "/account/licence_agreements/:id/cancel_request", :to => "user_licence_requests#cancel_request", :as => 'cancel_request'
  end

  resources :item_lists, :only => [:index, :show, :create, :destroy] do
      collection do
        post 'add_items'
      end

      member do
        post 'clear'
        get 'concordance_search'
        get 'frequency_search'
        get 'download_config_file'
        get 'download_item_list'
      end
  end

  # resources :media_items, :transcripts
  match '/eopas/:id' => 'transcripts#show', :as => 'eopas'

  match 'schema/json-ld' => 'catalog#annotation_context', :as => 'annotation_context'
  resources :issue_reports, :only => [:new, :create] do
  end

  resources :collections, :only => [:index, :show], :path => "/collections" do
  end

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

        #collection do
        #  get 'newLicenceForm'
        #  post 'createNewLicence'
        #end
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
