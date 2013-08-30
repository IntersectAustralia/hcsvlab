HcsvlabWeb::Application.routes.draw do
  root :to => "catalog#index"

  Blacklight.add_routes(self)
  get "catalog/:id/primary_text", :to => 'catalog#primary_text', :as => 'catalog_primary_text'
  get "catalog/:id/document/:filename", :to => 'catalog#document', :as => 'catalog_document', :format => false, :filename => /.*/
  get "catalog/:id/document/", :to => 'catalog#document', :as => 'catalog_document_api'
  get "catalog/:id/annotations", :to => 'catalog#annotations', :as => 'catalog_annotations'

  HydraHead.add_routes(self)
  
  devise_for :users, controllers: {registrations: "user_registers", passwords: "user_passwords"}

  devise_scope :user do
    get "/account/", :to => "user_registers#index" #allow users to edit their own password
    get "/account/edit", :to => "user_registers#edit" #allow users to edit their own password
    get "/account/edit_password", :to => "user_registers#edit_password" #allow users to edit their own password
    get "/account/licence_agreements", :to => "user_registers#licence_agreements" #allow users to edit their own password
    put "/account/update_password", :to => "user_registers#update_password" #allow users to edit their own password
    put "/account/generate_token", :to => "user_registers#generate_token" #allow users to generate an API token
    get "/account/download_token", :to => "user_registers#download_token"
    delete "/account/delete_token", :to => "user_registers#delete_token" #allow users to delete their API token
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
      end
  end

  # resources :media_items, :transcripts
  match '/eopas/:id' => 'transcripts#show', :as => 'eopas'

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
        end
      end

      resources :collection_lists, :only => [:index, :show, :new, :create, :destroy] do
        collection do
          post 'add_collections'
          post 'add_licence_to_collection_list'
          get 'remove_collection'
        end
      end

      resources :licences, :only => [:index, :new, :create], :path => "/licences" do
        get :index

        #collection do
        #  get 'newLicenceForm'
        #  post 'createNewLicence'
        #end
      end

    end
  end
end
