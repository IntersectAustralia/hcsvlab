class ItemList < ActiveRecord::Base
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  FIXNUM_MAX = 2147483647
  CONCORDANCE_PRE_POST_CHUNK_SIZE = 7


  belongs_to :user

  attr_accessible :name, :id, :user_id

  validates :name, presence: true

  #
  # Class variables for information about Solr
  #
  @@solr_config = nil
  @@solr = nil

  #
  # Initialise the connection to Solr
  #
  def get_solr_connection
    if @@solr_config.nil?
      @@solr_config = Blacklight.solr_config
      @@solr        = RSolr.connect(@@solr_config)
    end
  end

  #
  # Get the documents ids from given search parameters
  #
  def getAllItemsFromSearch(search_params)
    get_solr_connection

    params = eval(search_params)
    max_rows = 1000
    params['rows'] = max_rows
    response = @@solr.get('select', params: params)

    # If there are more rows in Solr than we asked for, increase the number we're
    # asking for and ask for them all this time. Sadly, there doesn't appear to be
    # a "give me everything" value for the rows parameter.
    if response["response"]["numFound"] > max_rows
        params['rows'] = response["response"]["numFound"]
        response = @@solr.get('select', params: params)
    end

    docs = Array.new
    response["response"]["docs"].each do |d|
      docs.push(d["id"])
    end
    return docs
  end

  #
  # Get list of URLs to send to galaxy
  #
  def get_galaxy_list
    ids = get_item_ids

    galaxy_list = ""
    ids.each_with_index do |id, index|
      begin
        uri = buildURI(id, 'primary_text')
        if index == 0
          galaxy_list += uri
        else
          galaxy_list += "," + uri
        end
      rescue
        Rails.logger.error("couldn't open primary text for item: " + id.to_s)
      end
    end

    return galaxy_list
  end

  #
  # Get the list of Item ids which this ItemList contains.
  # Return an array of Strings.
  #
  def get_item_ids
    get_solr_connection

    # The query is: give me items which have my item_list.id in their item_lists field
    params = {:start=>0, :q=>"item_lists:#{RSolr.escape(id.to_s)}", :fl=>"id"}
    max_rows = 100

    # First stab at the query
    params[:rows] = max_rows
    response = @@solr.get('select', params: params)

    # If there are more rows in Solr than we asked for, increase the number we're
    # asking for and ask for them all this time. Sadly, there doesn't appear to be
    # a "give me everything" value for the rows parameter.
    if response["response"]["numFound"] > max_rows
        params[:rows] = response["response"]["numFound"]
        response = @@solr.get('select', params: params)
    end

    # Now extract the ids from the response
    return response["response"]["docs"].map { |thingy| thingy["id"] }.sort
  end

  #
  # Get the list of Item catalog urls which this ItemList contains.
  # Return an array of Strings.
  #
  def get_item_urls(options = {})
    get_solr_connection

    # The query is: give me items which have my item_list.id in their item_lists field
    params = {:start=>0, :q=>"item_lists:#{RSolr.escape(id.to_s)}", :fl=>"id"}
    max_rows = 100

    # First stab at the query
    params[:rows] = max_rows
    response = @@solr.get('select', params: params)

    # If there are more rows in Solr than we asked for, increase the number we're
    # asking for and ask for them all this time. Sadly, there doesn't appear to be
    # a "give me everything" value for the rows parameter.
    if response["response"]["numFound"] > max_rows
        params[:rows] = response["response"]["numFound"]
        response = @@solr.get('select', params: params)
    end

    # Now extract the ids from the response
    return response["response"]["docs"].map { |thingy| thingy["id"] }.sort
  end

  #
  # Query Solr for all the Solr Documents describing the constituent
  # Items of this ItemList.
  # Return the response we get from Solr.
  #
  def get_items(start, rows)
    get_solr_connection

    rows = 20 if rows.nil?
    if start.nil?
      startValue = 0
    else
      startValue = (start.to_i-1)*rows.to_i
    end
    params = {:start => startValue, :rows => rows, :q=>"item_lists:#{RSolr.escape(id.to_s)}"}

    solrResponse = @@solr.get('select', params: params)
    response = Blacklight::SolrResponse.new(force_to_utf8(solrResponse), params)

    return response
  end
  
  #
  # Add some Items to this ItemList. The Items should be specified by
  # their ids. Don't add an Item which is already part of this ItemList.
  # Return a Set of the ids of the Items which were added.
  #
  def add_items(item_ids)
    bench_start = Time.now

    adding = Set.new(item_ids.map{ |item_id| item_id.to_s })
    adding.subtract(get_item_ids)

    # The variable adding now contains only the new ids

    adding.each { |item_id|
        # Get the specified Item's Solr Document
        params = {:q=>"id:#{RSolr.escape(item_id.to_s)}"}
        response = @@solr.get('select', params: params)

        # Check that we got something useful...
        if response == nil 
            Rails.logger.warn "No response from Solr when searching for Item #{item_id}"
        elsif response["response"] == nil
            Rails.logger.warn "Badly formed response from Solr when searching for Item #{item_id}"
        elsif response["response"]["numFound"] == 0
            Rails.logger.warn "Cannot find Item #{item_id} in Solr"
        elsif response["response"]["numFound"] > 1
            Rails.logger.warn "Multiple documents for Item #{item_id} in Solr"
        else
            #... and if we did, update it
            update_solr_field(item_id, :item_lists, id)
            #patch_after_update(item_id)
        end
    }

    Rails.logger.debug("Time for adding #{adding.size} docs to an item list: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    return adding
  end
  
  #
  # Add the contents of item_list to this ItemList.
  #
  def add_item_list(item_list)
    return add_items(item_list.get_item_ids)
  end
  
  #
  # Remove some Items from this ItemList. The Items should be specified by
  # their ids. Return a Set of the ids of the Items which were removed.
  #
  def remove_items(item_ids)
    item_ids = [item_ids] if item_ids.is_a?(String)
    removing = Set.new(item_ids.map{ |item_id| item_id.to_s }) & get_item_ids

    removing.each { |item_id|
        # Get the specified Item's Solr Document
        params = {:q=>"id:#{RSolr.escape(item_id.to_s)}"}
        response = @@solr.get('select', params: params)

        # Check that we got something useful...
        if response == nil 
            Rails.logger.warn "No response from Solr when searching for Item #{item_id}"
        elsif response["response"] == nil
            Rails.logger.warn "Badly formed response from Solr when searching for Item #{item_id}"
        elsif response["response"]["numFound"] == 0
            Rails.logger.warn "Cannot find Item #{item_id} in Solr"
        elsif response["response"]["numFound"] > 1
            Rails.logger.warn "Multiple documents for Item #{item_id} in Solr"
        else
            #... and if we did, remove our id from the Item's Solr
            # Document's item_lists field. Solr doesn't give us an
            # inverse to the 'add' operation we use in add_items(), and
            # 'set'ting with an array doesn't want to play, so
            # we reset the field to an empty array (with a 'set') and
            # then iterate over each value 'add'ing in the value. Empty
            # lists are wee bastards which I fake by using a list with
            # a single, unused ItemList id in ('.').

            document = response["response"]["docs"][0]
            current_ids = document["item_lists"]
            current_ids.delete('.')
            current_ids.delete(id.to_s)

            if current_ids.empty?
                clear_solr_field(item_id, :item_lists)
            else
                update_solr_field(item_id, :item_lists, current_ids[0], 'set')
                current_ids[1..-1].each { |current_id|
                    update_solr_field(item_id, :item_lists, current_id, 'add')
                }
            end
            #patch_after_update(item_id)
        end
    }

    return removing
  end
  
  #
  # Remove all Items from this ItemList.
  #
  def clear()
    return remove_items(get_item_ids)
  end

  #
  # Perform a Concordance search for a given term
  #
  def doConcordanceSearch(term)
    #pattern = /(([^\w-])|(^-\w+)|(\w+-$)|(-{2,}))/i
    pattern = /(([^\w])|(^-\w+)|(\w+-$))/i
    matchingWords = term.to_enum(:scan, pattern).map { Regexp.last_match }

    if matchingWords.length > 0
      result = {:error => "Concordance search allows only one word for searching. E.g. dog, dog-fighter"}
      return result
    end

    bench_start = Time.now

    # do matching only in the text. search for "dog," results in "dog", but search for "dog-fighter" results in "dog-fighter"
    search_for = term.match(/(\w+([-]?\w+)?)/i).to_s
    params = {}
    #params[:q] = 'full_text:"' + search_for + '"'
    params[:q] = "{!qf=full_text pf=''}#{search_for}"


    # Tells blacklight to call this method when it ends processing all the parameters that will be sent to solr
    self.solr_search_params_logic += [:add_concordance_solr_extra_filters]

    # get search result from solr
    (response, document_list) = get_search_results params

    #process the information
    highlighting = processAndHighlightManually(document_list, search_for)
    matchingDocs = document_list.size

    result = {:highlighting => highlighting, :matching_docs => matchingDocs}

    Rails.logger.debug("Time for searching for '#{search_for}' in concordance view: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    result
  end

  #
  # Perform a Frequency search for a given query
  #
  def doFrequencySearch(query, facet)
    bench_start = Time.now
    # Tells blacklight to call this method when it ends processing all the parameters that will be sent to solr
    self.solr_search_params_logic += [:add_frequency_solr_extra_filters]

    params = {}
    params[:'facet.field'] = facet
    # first I need to get all the facets and its values
    params[:q] = '*:*'
    (response, document_list) = get_search_results params
    all_facet_fields = response[:facet_counts][:facet_fields]

    # get search result from solr
    params[:q] = "{!qf=full_text pf=''}#{query}"
    params[:hl] = "on"
    params[:'hl.maxAnalyzedChars'] = -1 # indicate SOLR to process the whole text
    (response, document_list) = get_search_results params

    facet_fields = response[:facet_counts][:facet_fields]
    highlighting = response[:highlighting]

    #process the information
    result = executeFrequencySearch(all_facet_fields, facet_fields, document_list, highlighting, facet)

    Rails.logger.debug("Time for searching for '#{query}' in frequency view: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    result
  end

  private

  #
  # When you update the Solr document of an Item, it appears to throw
  # away the indexing of the Item's primary text. So, this patch will
  # regenerate the index. However, it does it slowly, we need to find a
  # much better way.
  #
  # Incidentally, Solr may well throw away other indexing, too, but
  # this has not manifested (yet).
  #
  # NOTE: This method is no longer needed since we are storing the primary text
  # and in that way solr is not loosing the indexes
  #
=begin
  def patch_after_update(item_id)
    puts item_id
    item = Item.find(item_id)
    unless item.primary_text.content.nil?
      update_solr_field(item_id, :full_text, item.primary_text.content, 'set')
    end
  end
=end

  def update_solr_field(item_id, field_id, field_value, mode='add')
    doc1 = {:id => item_id, field_id => field_value}
    add_attributes = {:allowDups => false, :commitWithin => 10}

    xml_update = @@solr.xml.add(doc1, add_attributes) do |doc2|
        doc2.field_by_name(field_id).attrs[:update] = mode
    end

    @@solr.update :data => xml_update
  end

  def clear_solr_field(item_id, field_id)
    # TODO: ermm, this, properly (see http://wiki.apache.org/solr/UpdateXmlMessages#Optional_attributes_for_.22field.22
    # and https://github.com/mwmitchell/rsolr)
    update_solr_field(item_id, field_id, '.', 'set')
  end

  def force_to_utf8(value)
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

  #
  # Process the documents returned in the concordance search, it highlights the searched term and
  # extract the surrounding words for each match
  #
  def processAndHighlightManually(document_list, search_for)
    charactersChunkSize = 200
    searchPattern = /(^|\W)(#{search_for})(\W|$)/i

    # Get document full text
    highlighting = {}
    document_list.each do |doc|
      full_text = doc[:full_text]

      highlighting[doc[:id]] = {}
      highlighting[doc[:id]][:title] = main_link_label(doc)
      highlighting[doc[:id]][:matches] = []

      # Iterate over everything that matches with the search in case-insensitive mode
      matchingData = full_text.to_enum(:scan, searchPattern).map { Regexp.last_match }
      matchingData.each { |m|
        # get the text preceding the match and extract the last 7 words
        pre = m.pre_match()
        pre = pre[-[pre.size, charactersChunkSize].min,charactersChunkSize].split(" ").last(CONCORDANCE_PRE_POST_CHUNK_SIZE).join(" ")

        # get the text after the match and extract the first 7 words
        post = m.post_match()[0,charactersChunkSize].split(" ").first(CONCORDANCE_PRE_POST_CHUNK_SIZE).join(" ")

        # since some special character might slip in the match, we do a second match to
        # add color only to the proper text.
        subMatch = m[2]
        subMatchPre = m[1]
        subMatchPost = m[3]

        # Add come color to the martching word
        highlightedText = "<span class='highlighting'>#{subMatch.to_s}</span>"

        formattedMatch = {}
        formattedMatch[:textBefore] = pre +  subMatchPre
        formattedMatch[:textAfter] = subMatchPost + post
        formattedMatch[:textHighlighted] = highlightedText

        highlighting[doc[:id]][:matches] << formattedMatch

      }
      Rails.logger.error("Solr has returned results for document id: #{doc[:id]} with title:'#{highlighting[doc[:id]][:title]}' but the highlighting procedure didn't find those results") if (highlighting[doc[:id]][:matches].empty?)

    end

    highlighting
  end

  #
  # Add extra parameters in SOLR filters for the Concordance search
  #
  def add_concordance_solr_extra_filters(solr_parameters, user_params)
    solr_parameters[:q] = user_params[:q]
    solr_parameters[:fq] = 'item_lists:' + id.to_s
    solr_parameters[:rows] = FIXNUM_MAX
  end

  #
  # Process all the information retrieved from SOLR.
  #
  def executeFrequencySearch(all_facet_fields, facet_fields, document_list, highlighting, facet_field_restriction)

    facetsWithResults = facet_fields[facet_field_restriction]
    allFacets = all_facet_fields[facet_field_restriction]

    # First I will obtain the facets and the number of documents matching with each one
    result = {}
    i = 0
    while (!allFacets.nil? and i < allFacets.size) do
      # Blacklight returns the facets setting the name of the facet in the even numbers, and the
      # number of document for that facet in the next index.
      facetValue = allFacets[i]

      result[facetValue] = {:num_docs => 0, :num_occurrences => 0}

      i = i + 2
    end

    i = 0
    while (i < facetsWithResults.size) do
      # Blacklight returns the facets setting the name of the facet in the even numbers, and the
      # number of document for that facet in the next index.
      facetValue = facetsWithResults[i]
      facetNumDocs = facetsWithResults[i+1]

      result[facetValue] = {:num_docs => facetNumDocs, :num_occurrences => 0}

      i = i + 2
    end

    # In order to get better performance, I will create a hash containing the facets for each document
    facetsByDocuments = extractFacetsFromDocuments(document_list, facet_field_restriction)

    # Count the occurrences of the search in the highlighted fragments returned by SOLR
    countOccurrences(highlighting, facetsByDocuments, facetValue, result)

    result
  end

  #
  # This method count the occurrences of the search in the returned highlighted results
  #
  def countOccurrences(highlighting, facetsByDocuments, facetValue, result)
    pattern = /(###\*\*\*###)(\w+)(###\*\*\*###)/i
    highlighting.each do |docId, value|
      facetValue = facetsByDocuments[docId]
      if (!facetValue.nil?)
        facetValue.each do |facet|
          # If for some reason the facet is not in the Hash, I won't make the process fail, but
          # I will show the text "###" in the number of documents. This should not happen.
          if (result[facet].nil?)
            result[facet] = {:num_docs => "###", :num_occurrences => 0}
          end
          if (!value[:full_text].nil?)
            value[:full_text].each do |aMatch|
              matchingData = aMatch.to_enum(:scan, pattern).map { Regexp.last_match }
              result[facet][:num_occurrences] = result[facet][:num_occurrences] + matchingData.size
            end
          else
            Rails.logger.error("Solr has returned results for document id: #{docId} but it didn't highlighted any match")
          end
        end
      end
    end
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
    solr_parameters[:fq] = 'item_lists:' + id.to_s
    solr_parameters[:rows] = FIXNUM_MAX
    solr_parameters[:facet] = "on"
    solr_parameters[:'facet.field'] = user_params[:'facet.field']
    solr_parameters[:'facet.limit'] = -1

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
end
