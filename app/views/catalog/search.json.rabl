node(:num_results) { |x| @response["response"]["numFound"] }
node(:items) { @response["response"]["docs"].collect { |item| catalog_url(item["handle"]) } }