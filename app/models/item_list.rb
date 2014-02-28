require "#{Rails.root}/lib/item_list/frequency_search_helper.rb"

class ItemList < ActiveRecord::Base
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  include FrequencySearchHelper

  FIXNUM_MAX = 2147483647
  CONCORDANCE_PRE_POST_CHUNK_SIZE = 7

  belongs_to :user

  attr_accessible :name, :id, :user_id

  validates :name, presence: true
  validates_length_of :name, :maximum => 255 , message:"Name is too long (maximum is 255 characters)"

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
      docs.push({id: d['id'], handle:d['handle']})
    end
    return docs
  end

  #
  # Get list of URLs to send to galaxy
  #
  def get_galaxy_list(root_url)
    ids = get_item_ids

    galaxy_list = ""
    ids.each_with_index do |id, index|
      uri = root_url + Rails.application.routes.url_helpers.catalog_primary_text_path(id)
      if index == 0
        galaxy_list += uri
      else
        galaxy_list += "," + uri
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
  # Get the list of Item handles which this ItemList contains.
  # Return an array of Strings.
  #
  def get_item_handles
    get_solr_connection

    # The query is: give me items which have my item_list.id in their item_lists field
    params = {:start=>0, :q=>"item_lists:#{RSolr.escape(id.to_s)}", :fl=>"handle"}
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
    return response["response"]["docs"].map { |thingy| thingy["handle"] }.sort
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
  def add_items(item_handles)
    bench_start = Time.now

    adding = Set.new(item_handles.map{ |item_handle| item_handle.to_s })
    adding.subtract(get_item_handles)

    # The variable adding now contains only the new ids

    verifiedIds = []
    adding.each { |item_id|
        # Get the specified Item's Solr Document
        params = {:q=>"handle:#{RSolr.escape(item_id.to_s)}"}
        response = @@solr.get('select', params: params)

        # Check that we got something useful...
        if response == nil 
            Rails.logger.warn "No response from Solr when searching for Item #{item_id}"
        elsif response["response"] == nil
            Rails.logger.warn "Badly formed response from Solr when searching for Item #{item_id}"
        elsif response["response"]["numFound"] == 0
            Rails.logger.warn "Cannot find Item #{item_id} in Solr"
            adding.delete(item_id)
        elsif response["response"]["numFound"] > 1
            Rails.logger.warn "Multiple documents for Item #{item_id} in Solr"
        else
            #... and if we did, update it
            #update_solr_field(item_id, :item_lists, id)
            verifiedIds << response['response']['docs'].first['id']
            #patch_after_update(item_id)
        end
    }

    if (!verifiedIds.empty?)
      update_solr_field_array(verifiedIds, :item_lists, id)
    end

    bench_end = Time.now
    Rails.logger.debug("Time for adding #{adding.size} items to an item list: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    profiler = ["Time for adding #{adding.size} items to an item list: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]

    return {addedItems: adding, profiler: profiler}
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
  # Generate R script for item list
  #
  def getRScript(root_url)
    return  "library(hcsvlab)\n" +
            "client <- RestClient(server_uri='#{root_url.chomp("/")}')\n" +
            "item_list <- client$get_item_list_by_id(#{self.id})"
  end

  #
  # Perform a Concordance search for a given term
  #
  def doConcordanceSearch(term)
    #pattern = /(([^\w-])|(^-\w+)|(\w+-$)|(-{2,}))/i
    pattern = /(([^\w])|(^-\w+)|(\w+-$))/i
    matchingWords = term.to_enum(:scan, pattern).map { Regexp.last_match }

    if (matchingWords.length > 0 or term.empty?)
      result = {:error => "Concordance search allows only one word for searching. E.g. dog, cat, etc."}
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

    process_bench_start = Time.now

    #process the information
    highlighting = processAndHighlightManually(document_list, search_for)

    process_bench_end = Time.now

    Rails.logger.debug("Time for data processing for term '#{search_for}' in concordance search: (#{'%.1f' % ((process_bench_end.to_f - process_bench_start.to_f)*1000)}ms)")

    matchingDocs = document_list.size
    profiling = []
    profiling << "Time for data processing for term '#{search_for}' in concordance search: (#{'%.1f' % ((process_bench_end.to_f - process_bench_start.to_f)*1000)}ms)"

    result = {:highlighting => highlighting, :matching_docs => matchingDocs, :profiler => profiling}

    bench_end = Time.now

    Rails.logger.debug("Time for searching for '#{search_for}' in concordance search: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    profiling << "Time for searching for '#{search_for}' in concordance search: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"

    result
  end

  #
  # Perform a Frequency search for a given query
  #
  def doFrequencySearch(query, facet)
    if (query.strip.empty?)
      result = {:status => "INPUT_ERROR", :message => "Frequency search does not allow empty searches"}
      return result
    end

    pattern = /(([^\w])|(^-\w+)|(\w+-$))/i
    matchingWords = query.to_enum(:scan, pattern).map { Regexp.last_match }

    if (matchingWords.length > 0)
      result = ComplexFrequencySearch.new.executeFrequencySearchOnComplexTerm(query, facet, id)
    else
      result = SimpleFrequencySearch.new.executeFrequencySearchOnSimpleTerm(query, facet, id)
    end

    if (result.nil? || result.empty?)
      result = {:status => "NO_MATCHING_DOCUMENTS"}
    elsif (result[:status].nil?)
      result[:status] = "OK"
    end

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

  def update_solr_field_array(item_ids, field_id, field_value, mode='add')
    docs = []
    item_ids.each do |item_id|
      doc1 = {:id => item_id, field_id => field_value}
      docs << doc1
    end
      add_attributes = {:allowDups => false, :commitWithin => 10}

      xml_update = @@solr.xml.add(docs, add_attributes) do |doc2|
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
  # blacklight uses this method to get the SOLR connection.
  #
  def blacklight_solr
    get_solr_connection
    @@solr
  end
end
