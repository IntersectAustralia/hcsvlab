module Hcsvlab_Blacklight

  def self.add_routes(router, options = {})
    Hcsvlab_Blacklight::Routes.new(router, options).draw
  end

  class Routes < Blacklight::Routes
    module RouteSets
      def catalog
        add_routes do |options|
          # Catalog stuff.
          get 'catalog/opensearch', :as => "opensearch_catalog"
          get 'catalog/citation', :as => "citation_catalog"
          get 'catalog/email', :as => "email_catalog"
          post 'catalog/email'
          get 'catalog/sms', :as => "sms_catalog"
          get 'catalog/endnote', :as => "endnote_catalog"
          get 'catalog/send_email_record', :as => "send_email_record_catalog"
          get "catalog/facet/:id", :to => 'catalog#facet', :as => 'catalog_facet'


          #get "catalog", :to => 'catalog#index', :as => 'catalog_index'

          #get 'catalog/:id/librarian_view', :to => "catalog#librarian_view", :as => "librarian_view_catalog"
        end
      end

    end
  end
end