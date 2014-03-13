class RdfNamespace

  SESAME_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/sesame.yml")[Rails.env] unless defined? SESAME_CONFIG
  RDF_NAMESPACE = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

  #
  # Get all namespaces for a given repository
  #
  def self.get_namespaces(repo)
    uri = URI("#{SESAME_CONFIG["url"]}/repositories/#{repo}/namespaces")

    # Send the request to the sparql endpoint.
    req = Net::HTTP::Get.new(uri)
    req.add_field("accept", "application/json")
    res = Net::HTTP.new(uri.host, uri.port).start do |http|
      http.request(req)
    end

    # If sesame returns an error, then we show the error received by sesame
    if (!res.is_a?(Net::HTTPSuccess))
      Rails.logger.error(res.body)
      raise Exception.new
    else
      namespaces = Hash[JSON.parse(res.body)["results"]["bindings"].collect { |entry| [entry["prefix"]["value"], entry["namespace"]["value"]]}]
    end
    # Add in RDF namespace manually as it may not always be in triplestore namespaces
    namespaces["rdf"] = RDF_NAMESPACE
    return namespaces
  end

  #
  # Get the shortened URI (prefix:value) for a whole URI if found in the given namespaces
  #
  def self.get_shortened_uri(uri, namespaces)
    namespaces.each do |k,v|
      if uri.include? v and !uri.gsub(v, "").include? "/" and !uri.gsub(v, "").include? "#"
        return k + ":" + uri.gsub(v, "")
      end
    end
    return uri
  end

end