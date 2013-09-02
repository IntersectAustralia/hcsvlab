module SolrHelper

  #
  # Class variables for information about Solr
  #
  @@solr_config = nil
  @@solr = nil

  #
  # Initialise the connection to Solr
  #
  def self.get_solr_connection
    if @@solr_config.nil?
      @@solr_config = Blacklight.solr_config
      @@solr        = RSolr.connect(@@solr_config)
    end
  end

  #
  # Search for an object in Solr to see if we need to add or update
  #
  def self.object_exists_in_solr?(object)
    response = @@solr.get 'select', :params => { :q => object }
    (response['response']['docs'].count > 0) ? true : false
  end

  #
  # Update Solr with the information we've found
  #
  def self.store_object(object, fieldsToRemove = [])
    solr_object = object.to_solr
    keysToRemove = []
    fieldsToRemove.each do |fieldName|
      keysToRemove << solr_object.select {|k,v| k.match(/#{fieldName}/)}.map {|k,v| k}
    end

    keysToRemove.flatten.each do |key|
      solr_object.delete(key)
    end

    get_solr_connection()
    if (object_exists_in_solr?(object))
      logger.debug "Updating " + object.to_s
      response = @@solr.update :data => solr_object
      logger.debug("Update response= #{response.to_s}")
    else
      logger.debug "Inserting " + object.to_s
      response = @@solr.add(solr_object)
    end
    response = @@solr.commit
    logger.debug("Commit response= #{response.to_s}")
  end
end