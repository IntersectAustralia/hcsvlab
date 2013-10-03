module FrequencySearchHelper

  class SimpleFrequencySearch
    include Blacklight::BlacklightHelperBehavior
    include Blacklight::Configurable
    include Blacklight::SolrHelper

    FIXNUM_MAX = 2147483647

    #
    # Class variables for information about Solr
    #
    @@solr_config = nil
    @@solr = nil

    def executeFrequencySearchOnSimpleTerm(query, facet, itemListId)
      bench_start = Time.now

      self.solr_search_params_logic += [:add_frequency_solr_extra_filters]

      params = {}
      params[:'facet.field'] = facet
      params[:fq] = 'item_lists:' + itemListId.to_s
      # first I need to get all the facets and its values
      params[:q] = '*:*'

      params[:fl] = %w(id AUSNC_itemwordcount_tesim)
      params[:fl] << facet

      (response, document_list) = get_search_results params
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
        facet_value = document[facet][0]
        words = document["AUSNC_itemwordcount_tesim"]
        if words.nil?
          no_words_count += 1
        else
          words = document["AUSNC_itemwordcount_tesim"][0].to_i
          all_facet_wcs[facet_value] = all_facet_wcs[facet_value] + words
        end
      }

      # get search result from solr
      params[:q] = "{!qf=full_text pf=''}#{query}"
      params[:'hl.maxAnalyzedChars'] = -1 # indicate SOLR to process the whole text
      params[:fl] = "id, #{facet}, TF1:termfreq(full_text,'#{query}')"

      (response, document_list) = get_search_results params

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
        docId = aDocument.id

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
      solr_parameters[:fq] = user_params[:fq]
      solr_parameters[:rows] = FIXNUM_MAX
      solr_parameters[:facet] = "on"
      solr_parameters[:'facet.field'] = user_params[:'facet.field']
      solr_parameters[:'facet.limit'] = -1

      solr_parameters[:fl] = user_params[:fl]
    end

    #
    # blacklight uses this method to get the SOLR connection.
    #
    def blacklight_solr
      get_solr_connection
      @@solr
    end

    #
    # Initialise the connection to Solr
    #
    def get_solr_connection
      if @@solr_config.nil?
        @@solr_config = Blacklight.solr_config
        @@solr        = RSolr.connect(@@solr_config)
      end
    end

  end

  class ComplexFrequencySearch
    include Blacklight::BlacklightHelperBehavior
    include Blacklight::Configurable
    include Blacklight::SolrHelper

    FIXNUM_MAX = 2147483647

    #
    # Class variables for information about Solr
    #
    @@solr_config = nil
    @@solr = nil

    def executeFrequencySearchOnComplexTerm(query, facet, itemListId)
      bench_start = Time.now
      # Tells blacklight to call this method when it ends processing all the parameters that will be sent to solr
      self.solr_search_params_logic += [:add_frequency_solr_extra_filters]

      params = {}
      params[:'facet.field'] = facet
      # first I need to get all the facets and its values

      params[:q] = '*:*'
      params[:fl] = %w(id AUSNC_itemwordcount_tesim)
      params[:fl] << facet
      params[:fq] = 'item_lists:' + itemListId.to_s

      (response, document_list) = get_search_results params
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
        facet_value = document[facet][0]
        words = document["AUSNC_itemwordcount_tesim"]
        if words.nil?
          no_words_count += 1
        else
          words = document["AUSNC_itemwordcount_tesim"][0].to_i
          all_facet_wcs[facet_value] = all_facet_wcs[facet_value] + words
        end
      }

      # get search result from solr
      params[:q] = "{!qf=full_text pf=''}#{query}"
      params.delete(:fl)
      params[:hl] = "on"
      params[:tv] = "false"
      params[:'hl.maxAnalyzedChars'] = -1 # indicate SOLR to process the whole text

      (response, document_list) = get_search_results params

      facet_fields = response[:facet_counts][:facet_fields]
      highlighting = response[:highlighting]
      termVectors = response[:termVectors]

      process_bench_start = Time.now

      #process the information
      result = processComplexFrequencySearchResults(all_facet_fields, all_facet_wcs, facet_fields, document_list, highlighting, facet)

      Rails.logger.debug("Data processing time for '#{query}' in Complex frequency search: (#{'%.1f' % ((Time.now.to_f - process_bench_start.to_f)*1000)}ms)")

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
      solr_parameters[:fq] = user_params[:fq]
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
    end

    #
    # blacklight uses this method to get the SOLR connection.
    #
    def blacklight_solr
      get_solr_connection
      @@solr
    end

    #
    # Initialise the connection to Solr
    #
    def get_solr_connection
      if @@solr_config.nil?
        @@solr_config = Blacklight.solr_config
        @@solr        = RSolr.connect(@@solr_config)
      end
    end
  end

  class SearchUtils
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

  end

end