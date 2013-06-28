HcsvlabWeb::Application.routes.draw do
  root :to => "catalog#index"

  Blacklight.add_routes(self)
  get "catalog/:id/primary_text", :to => 'catalog#primary_text', :as => 'catalog_primary_text'
  get "catalog/:id/document/:filename", :to => 'catalog#document', :as => 'catalog_document', :format => false, :filename => /.*/

  HydraHead.add_routes(self)
  
  devise_for :users, controllers: {registrations: "user_registers", passwords: "user_passwords"}

  devise_scope :user do
    get "/users/edit_password", :to => "user_registers#edit_password" #allow users to edit their own password
    put "/users/update_password", :to => "user_registers#update_password" #allow users to edit their own password
    put "/users/generate_token", :to => "user_registers#generate_token" #allow users to generate an API token
    get "/users/download_token", :to => "user_registers#download_token"
    delete "/users/delete_token", :to => "user_registers#delete_token" #allow users to delete their API token
  end

  resources :users, :only => [:show] do

    collection do
      get :access_requests
      get :index
      get :admin
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

  resources :item_lists, :only => [:index, :show, :create, :destroy] do
      collection do
        post 'add_items'
      end

      member do
        post 'clear'
        get 'concordance_search'
        get 'frequency_search'
      end
  end

  # resources :media_items, :transcripts
  match '/eopas/:id' => 'transcripts#show', :as => 'eopas'

end
