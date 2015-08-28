module Blacklight::SolrHelper::Overrides

  # This overrides the BlackLight gems query_solr method so that POST
  # requests are used for queries instead of GETs, to avoid the problem
  # where large GET queries are truncated and break Alveo.
  def query_solr(user_params = params || {}, extra_controller_params = {})
    
    if Blacklight::version != '4.2.1'
      raise 'This method modifies the default Blacklight::SolrHelper#query_solr method. ' \
            'Update it everytime the gem is updated and remove it entirely for gem versions ' \
            '5.0.0 and above, where the request method has become a configurable parameters.'
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


end