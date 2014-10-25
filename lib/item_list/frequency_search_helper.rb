module FrequencySearchHelper

  class SimpleFrequencySearch
    include Blacklight::BlacklightHelperBehavior
    include Blacklight::Configurable
    include Blacklight::SolrHelper

    FIXNUM_MAX = 2147483647

    #
    #
    #
    def executeFrequencySearchOnSimpleTerm(query, facet, itemList)
      bench_start = Time.now

      handles = itemList.get_authorised_item_handles()

      params = {}
      params[:'facet.field'] = facet

      params[:fl] = %w(id AUSNC_itemwordcount_tesim)
      params[:fl] << facet

      # Merge the base parameters with some extra parameters needed for the search
      mergedParams = params.merge(add_frequency_solr_extra_filters({}, params))
      # Send request to solr and retrieve the results.
      document_list, response = SearchUtils.retrieveDocumentsFromSolr(mergedParams, handles)

      all_facet_fields = response[:facet_counts][:facet_fields]

      if (all_facet_fields[facet].nil? || all_facet_fields[facet].empty?)
        result = {:status => "NO_FACET_VALUES_DEFINED"}
        return result
      end

      # Get the total word counts
      all_facet_wcs = {}
      no_words_count = 0
      all_facet_fields[facet].each_index { |i|
        all_facet_wcs[all_facet_fields[facet][i]] = 0 if i%2 == 0
      }
      document_list.each { |document|
        if (document[facet].present?)
          facet_value = document[facet][0]
          words = document["AUSNC_itemwordcount_tesim"]
          if words.nil?
            no_words_count += 1
          else
            words = document["AUSNC_itemwordcount_tesim"][0].to_i
            all_facet_wcs[facet_value] = all_facet_wcs[facet_value] + words
          end
        end
      }

      # get search result from solr
      params[:q] = "{!qf=full_text pf=''}#{query}"
      params[:'hl.maxAnalyzedChars'] = -1 # indicate SOLR to process the whole text
      params[:fl] = "id, #{facet}, TF1:termfreq(full_text,'#{query}')"

      # Merge the base parameters with some extra parameters needed for the search
      mergedParams = params.merge(add_frequency_solr_extra_filters({}, params))
      # Send request to solr and retrieve the results.
      document_list, response = SearchUtils.retrieveDocumentsFromSolr(mergedParams, handles)

      facet_fields = response[:facet_counts][:facet_fields]
      highlighting = response[:highlighting]
      termVectors = response[:termVectors]

      process_bench_start = Time.now

      #process the information
      result = processSimpleFrequencySearchResults(all_facet_fields, all_facet_wcs, facet_fields, document_list, termVectors, facet, query)

      Rails.logger.debug("Data processing time for '#{query}' in Simple frequency search: (#{'%.1f' % ((Time.now.to_f - process_bench_start.to_f)*1000)}ms)")

      Rails.logger.debug("Time for searching for '#{query}' in Simple frequency search: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

      result
    end

    private

    #
    #
    #
    def processSimpleFrequencySearchResults(all_facet_fields, all_facet_wcs, facet_fields, document_list, termVectors, facet_field_restriction, query)
      facetsWithResults = facet_fields[facet_field_restriction]
      allFacets = all_facet_fields[facet_field_restriction]

      # First I will obtain the facets and the number of documents matching with each one
      result = {}
      result[:data] = {}
      i = 0
      while (!allFacets.nil? and i < allFacets.size) do
        # Blacklight returns the facets setting the name of the facet in the even numbers, and the
        # number of document for that facet in the next index.
        facetValue = allFacets[i]

        result[:data][facetValue] = {:num_docs => 0, :num_occurrences => 0,
                                     :total_docs => allFacets[i+1], :total_words => all_facet_wcs[facetValue]}

        i = i + 2
      end

      i = 0
      while (i < facetsWithResults.size) do
        # Blacklight returns the facets setting the name of the facet in the even numbers, and the
        # number of document for that facet in the next index.
        facetValue = facetsWithResults[i]
        facetNumDocs = facetsWithResults[i+1]

        result[:data][facetValue][:num_docs] = facetNumDocs

        i = i + 2
      end

      # In order to get better performance, I will create a hash containing the facets for each document
      facetsByDocuments = SearchUtils.extractFacetsFromDocuments(document_list, facet_field_restriction)

      # Count the occurrences of the search in the highlighted fragments returned by SOLR
      document_list.each do |aDocument|
        docId = aDocument['id']

        facetValue = facetsByDocuments[docId]
        if (!facetValue.nil?)
          facetValue.each do |facet|
            # If for some reason the facet is not in the Hash, I won't make the process fail, but
            # I will show the text "###" in the number of documents. This should not happen.
            if (result[:data][facet].nil?)
              result[:data][facet][:num_docs] = "###"
              result[:data][facet][:num_occurrences] = 0
            end
            result[:data][facet][:num_occurrences] = result[:data][facet][:num_occurrences] + aDocument[:TF1]
          end
        end

      end

      result
    end

    #
    # This method creates a Hash containing the values of an specified facet in a document
    #
    def extractFacetsFromDocuments(document_list, facet_field_restriction)
      result = {}
      document_list.each do |aDoc|
        result[aDoc[:id]] = aDoc[facet_field_restriction]
      end
      result
    end

    #
    # This method adds extra parameters to the SOLR search.
    #
    def add_frequency_solr_extra_filters(solr_parameters, user_params)
      solr_parameters[:rows] = FIXNUM_MAX
      solr_parameters[:facet] = "on"
      solr_parameters[:'facet.field'] = user_params[:'facet.field']
      solr_parameters[:'facet.limit'] = -1

      solr_parameters[:fl] = user_params[:fl]
      solr_parameters
    end
  end

  class ComplexFrequencySearch
    include Blacklight::BlacklightHelperBehavior
    include Blacklight::Configurable
    include Blacklight::SolrHelper

    FIXNUM_MAX = 2147483647

    #
    #
    #
    def executeFrequencySearchOnComplexTerm(query, facet, itemList)
      bench_start = Time.now

      handles = itemList.get_authorised_item_handles()

      params = {}
      params[:'facet.field'] = facet
      # first I need to get all the facets and its values

      params[:fl] = %w(id AUSNC_itemwordcount_tesim)
      params[:fl] << facet

      # Merge the base parameters with some extra parameters needed for the search
      mergedParams = params.merge(add_frequency_solr_extra_filters({}, params))
      # Send request to solr and retrieve the results.
      document_list, response = SearchUtils.retrieveDocumentsFromSolr(mergedParams, handles)

      all_facet_fields = response[:facet_counts][:facet_fields]

      if (all_facet_fields[facet].nil? || all_facet_fields[facet].empty?)
        result = {:status => "NO_FACET_VALUES_DEFINED"}
        return result
      end

      # Get the total word counts
      all_facet_wcs = {}
      no_words_count = 0
      all_facet_fields[facet].each_index { |i|
        all_facet_wcs[all_facet_fields[facet][i]] = 0 if i%2 == 0
      }
      document_list.each { |document|
        if (document[facet].present?)
          facet_value = document[facet][0]
          words = document["AUSNC_itemwordcount_tesim"]
          if words.nil?
            no_words_count += 1
          else
            words = document["AUSNC_itemwordcount_tesim"][0].to_i
            all_facet_wcs[facet_value] = all_facet_wcs[facet_value] + words
          end
        end
      }

      # get search result from solr
      params[:q] = "{!qf=full_text pf=''}#{query}"
      params.delete(:fl)
      params[:hl] = "on"
      params[:tv] = "false"
      params[:'hl.maxAnalyzedChars'] = -1 # indicate SOLR to process the whole text

      # Merge the base parameters with some extra parameters needed for the search
      mergedParams = params.merge(add_frequency_solr_extra_filters({}, params))
      # Send request to solr and retrieve the results.
      document_list, response = SearchUtils.retrieveDocumentsFromSolr(mergedParams, handles)

      facet_fields = response[:facet_counts][:facet_fields]
      highlighting = response[:highlighting]
      highlighting = {} if highlighting.nil?
      termVectors = response[:termVectors]

      process_bench_start = Time.now

      #process the information
      result = processComplexFrequencySearchResults(all_facet_fields, all_facet_wcs, facet_fields, document_list, highlighting, facet)

      Rails.logger.debug("Time for data processing for query '#{query}' in Complex frequency search: (#{'%.1f' % ((Time.now.to_f - process_bench_start.to_f)*1000)}ms)")

      Rails.logger.debug("Time for searching for '#{query}' in Complex frequency search: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

      result
    end

    private

    #
    # Process all the information retrieved from SOLR.
    #
    def processComplexFrequencySearchResults(all_facet_fields, all_facet_wcs, facet_fields, document_list, highlighting, facet_field_restriction)

      facetsWithResults = facet_fields[facet_field_restriction]
      allFacets = all_facet_fields[facet_field_restriction]

      # First I will obtain the facets and the number of documents matching with each one
      result = {}
      result[:data] = {}
      i = 0
      while (!allFacets.nil? and i < allFacets.size) do
        # Blacklight returns the facets setting the name of the facet in the even numbers, and the
        # number of document for that facet in the next index.
        facetValue = allFacets[i]

        result[:data][facetValue] = {:num_docs => 0, :num_occurrences => 0,
                                     :total_docs => allFacets[i+1], :total_words => all_facet_wcs[facetValue]}

        i = i + 2
      end

      i = 0
      while (i < facetsWithResults.size) do
        # Blacklight returns the facets setting the name of the facet in the even numbers, and the
        # number of document for that facet in the next index.
        facetValue = facetsWithResults[i]
        facetNumDocs = facetsWithResults[i+1]

        result[:data][facetValue][:num_docs] = facetNumDocs

        i = i + 2
      end

      # In order to get better performance, I will create a hash containing the facets for each document
      facetsByDocuments = SearchUtils.extractFacetsFromDocuments(document_list, facet_field_restriction)

      # Count the occurrences of the search in the highlighted fragments returned by SOLR
      countOccurrences(highlighting, facetsByDocuments, facetValue, result)

      result
    end

    #
    # This method count the occurrences of the search in the returned highlighted results
    #
    def countOccurrences(highlighting, facetsByDocuments, facetValue, result)
      pattern = /(###\*\*\*###)(\S+)(###\*\*\*###)/i
      highlighting.each do |docId, value|
        facetValue = facetsByDocuments[docId]
        if (!facetValue.nil?)
          facetValue.each do |facet|
            # If for some reason the facet is not in the Hash, I won't make the process fail, but
            # I will show the text "###" in the number of documents. This should not happen.
            if (result[:data][facet].nil?)
              result[:data][facet][:num_docs] = "###"
              result[:data][facet][:num_occurrences] = 0
            end
            if (!value[:full_text].nil?)
              value[:full_text].each do |aMatch|
                matchingData = aMatch.to_enum(:scan, pattern).map { Regexp.last_match }
                result[:data][facet][:num_occurrences] = result[:data][facet][:num_occurrences] + matchingData.size
              end
            else
              Rails.logger.error("Solr has returned results for document id: #{docId} but it didn't highlighted any match")
            end
          end
        end
      end
    end

    #
    # This method adds extra parameters to the SOLR search.
    #
    def add_frequency_solr_extra_filters(solr_parameters, user_params)
      solr_parameters[:rows] = FIXNUM_MAX
      solr_parameters[:facet] = "on"
      solr_parameters[:'facet.field'] = user_params[:'facet.field']
      solr_parameters[:'facet.limit'] = -1

      solr_parameters[:tv] = user_params[:tv]
      solr_parameters[:"tv.tf"] = true

      #highlighting parameters
      solr_parameters[:hl] = user_params[:hl]
      solr_parameters[:'hl.fl'] = "full_text"
      solr_parameters[:'hl.snippets'] = 1000
      solr_parameters[:'hl.simple.pre'] = "###***###" # indicate SOLR to surround the matching text with this chars
      solr_parameters[:'hl.simple.post'] = "###***###" # indicate SOLR to surround the matching text with this chars
      solr_parameters[:'hl.fragsize'] = 0
      if (!user_params[:'hl.maxAnalyzedChars'].nil?)
        solr_parameters[:'hl.maxAnalyzedChars'] = user_params[:'hl.maxAnalyzedChars']
      end

      solr_parameters
    end

  end

  class SearchUtils
    #
    # Class variables for information about Solr
    #
    @@solr = nil

    #
    # This method creates a Hash containing the values of an specified facet in a document
    #
    def self.extractFacetsFromDocuments(document_list, facet_field_restriction)
      result = {}
      document_list.each do |aDoc|
        result[aDoc[:id]] = aDoc[facet_field_restriction]
      end
      result
    end

    #
    # This method will send a request request to solr and retrieve the
    # documents list and the response object
    #
    def self.retrieveDocumentsFromSolr(params, itemHandles, batch_group=50)
      # If the :start and :rows symbols are defined, we need to only search the
      # items handles in that range. Otherwise we search for everything
      if (params[:start].present? and params[:rows].present?)
        itemHandlesLimited = itemHandles[params[:start]..params[:start]+params[:rows]-1]
      else
        itemHandlesLimited = itemHandles
      end

      get_solr_connection()
      document_list = []
      facet_fields = {}
      highlighting = {}
      itemHandlesLimited.in_groups_of(batch_group, false) do |groupOfItemHandles|
        condition = groupOfItemHandles.map{|handle| "handle:\"#{handle.gsub(":", "\:")}\""}.join(" OR ")

        # We will filter the results using the :fq query field. If the :d field was not previouly defined
        # we have to set it to *:* in order to bring everything
        queryParams = {q:"*:*"}
        queryParams[:fq] = condition

        # If the :q parameter was defined, we override the defined *:*
        queryParams.merge!(params)

        # since we are using :fq parameter, we need to tell solr to make the query from :start=0
        # Otherwise it will apply the :fq restriction and after that will apply the :start one. so
        # if your :fq parameter bring 20 items and your :start is 20, then no items will be returned.
        queryParams[:start] = 0

        solrResponse = @@solr.get('select', params: queryParams)
        response = Blacklight::SolrResponse.new(force_to_utf8(solrResponse), params)

        document_list += response['response']['docs']

        # Since we are querying solr in chucks, we need to consolidate the results of each group.
        facet_fields = consolidateFacetFields(facet_fields, response)

        if (response['highlighting'].present?)
          highlighting.merge!(response['highlighting'])
        end
      end

      response = {}
      response['response'] = {'numFound'=>itemHandles.length, 'start'=>((params[:start].present?)?params[:start]:0), 'docs'=>document_list}
      response['facet_counts'] = {'facet_fields' => facet_fields}
      if (!highlighting.empty?)
        response['highlighting'] = highlighting
      end
      response = Blacklight::SolrResponse.new(force_to_utf8(response), params)

      return document_list, response

    end

    private

    #
    # This method will consolidate the values in facet_fields with the ones
    # retrieved from solr.
    # Basically, Solr retrieves the facet_fields count as an array, where the even
    # positions contain the name and the add ones contains the count.
    # E.g. ["cooee", 10, "ace" 20]
    #
    def self.consolidateFacetFields(facet_fields, response)
      # If we have not fields defined, then just use the ones retrieved
      if (facet_fields.empty?)
        facet_fields = response['facet_counts']['facet_fields']
      else
        # Otherwise we need to look for the values in the previously loaded hash
        response['facet_counts']['facet_fields'].each_pair do |key, value|
          # If the facet field was not included, then just use the retrieved one
          if (!facet_fields.include?(key))
            facet_fields[key] = value
          else
            # Otherwise, we need to consolidate both arrays adding up in the case
            # where both the arrays contain the same name.
            i = 0
            while (i < value.length)
              name = value[i]
              count = value[i+1]
              # verify if the array already have the name
              valuePos = facet_fields[key].index(name)
              if (valuePos.nil?)
                facet_fields[key] << name
                facet_fields[key] << count
              else
                facet_fields[key][valuePos+1] = facet_fields[key][valuePos+1] + count
              end
              i = i +2
            end
          end
        end
      end
      facet_fields
    end

    #
    # Initialise the connection to Solr
    #
    def self.get_solr_connection
      if @@solr.nil?
        solr_config = Blacklight.solr_config
        @@solr        = RSolr.connect(solr_config)
      end
    end

    #
    #
    #
    def self.force_to_utf8(value)
      case value
        when Hash
          value.each { |k, v| value[k] = force_to_utf8(v) }
        when Array
          value.each { |v| force_to_utf8(v) }
        when String
          value.force_encoding("utf-8")  if value.respond_to?(:force_encoding)
      end
      value
    end
  end
end