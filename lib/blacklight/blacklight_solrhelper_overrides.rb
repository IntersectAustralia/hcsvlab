module Blacklight::SolrHelper::Overrides

  # This overrides the BlackLight gems query_solr method so that POST
  # requests are used for queries instead of GETs, to avoid the problem
  # where large GET queries are truncated and break Alveo.
  def query_solr(user_params = params || {}, extra_controller_params = {})
    
    if Blacklight::version != '4.2.1'
      raise 'This method modifies the default Blacklight::SolrHelper#query_solr method. ' \
            'Update it everytime the gem is updated and remove it entirely for gem versions ' \
            '5.0.0 and above, where the request method has become a configurable parameter.'
    end
    
    bench_start = Time.now
    solr_params = self.solr_search_params(user_params).merge(extra_controller_params)
    solr_params[:qt] ||= blacklight_config.qt
    path = blacklight_config.solr_path

    # delete these parameters, otherwise rsolr will pass them through.
    res = blacklight_solr.send_and_receive(path, :data=>solr_params, :method => :post)
    
    solr_response = Blacklight::SolrResponse.new(force_to_utf8(res), solr_params)

    Rails.logger.debug("Solr query: #{solr_params.inspect}")
    Rails.logger.debug("Solr response: #{solr_response.inspect}") if defined?(::BLACKLIGHT_VERBOSE_LOGGING) and ::BLACKLIGHT_VERBOSE_LOGGING
    Rails.logger.debug("Solr fetch: #{self.class}#query_solr (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
    
    solr_response
  end

  # # calls setup_previous_document then setup_next_document.
  # # used in the show action for single view pagination.
  # def setup_next_and_previous_documents
  #   setup_previous_document
  #   setup_next_document
  # end
  #
  # def setup_previous_document
  #   @previous_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i - 1) : nil
  # end
  #
  # def setup_next_document
  #   @next_document = session[:search][:counter] ? setup_document_by_counter(session[:search][:counter].to_i + 1) : nil
  # end
  #
  # # gets a document based on its position within a resultset
  # def setup_document_by_counter(counter)
  #   return if counter < 1 || session[:search].blank?
  #   search = session[:search] || {}
  #   get_single_doc_via_search(counter, search)
  # end
  #
  # # a solr query method
  # # this is used when selecting a search result: we have a query and a
  # # position in the search results and possibly some facets
  # # Pass in an index where 1 is the first document in the list, and
  # # the Blacklight app-level request params that define the search.
  # def get_single_doc_via_search(index, request_params)
  #   solr_params = solr_search_params(request_params)
  #   solr_params[:start] = (index - 1) # start at 0 to get 1st doc, 1 to get 2nd.
  #   solr_params[:rows] = 1
  #   solr_params[:fl] = '*'
  #   solr_response = find(blacklight_config.qt, solr_params)
  #   SolrDocument.new(solr_response.docs.first, solr_response) unless solr_response.docs.empty?
  # end

  # This overrides the BlackLight gems find method so that POST
  # requests are used for queries instead of GETs, to avoid the problem
  # where large GET queries are truncated and break Alveo.
  def find(*args)
    if Blacklight::version != '4.2.1'
      raise 'This method modifies the default Blacklight::SolrHelper#query_solr method. ' \
            'Update it everytime the gem is updated and remove it entirely for gem versions ' \
            '5.0.0 and above, where the request method has become a configurable parameter.'
    end

    path = blacklight_config.solr_path
    # response = blacklight_solr.get(path, :params=> args[1])
    response = blacklight_solr.send_and_receive(path, :data=>args[1], :method => :post)
    Blacklight::SolrResponse.new(force_to_utf8(response), args[1])
  rescue Errno::ECONNREFUSED => e
    raise Blacklight::Exceptions::ECONNREFUSED.new("Unable to connect to Solr instance using #{blacklight_solr.inspect}")
  end



end