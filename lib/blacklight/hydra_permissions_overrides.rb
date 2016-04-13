module Hydra
  module PermissionsQuery

    protected

    # Hydra's permission system assumes that Solr's unique key is 
    # the Postgres ID of the indexed item. This creates an unnecessary
    # dependency between the DB and Solr that prevents asynchronous
    # ingest i.e. something has to be stored in the DB first so we can
    # get the DB ID before it is indexed in Solr. To cicumvent this
    # dependency we use the 'handle' to uniquely identify an item
    def permissions_solr_doc_params(id=nil)
      id ||= params[:id]
      # just to be consistent with the other solr param methods:
      {
        :qt => :permissions,
        :handle => id # this assumes the document request handler will map the 'id' param to the unique key field
      }
    end
  end    
end
