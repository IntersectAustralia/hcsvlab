require "#{Rails.root}/lib/item_list/frequency_search_helper.rb"

class ItemList < ActiveRecord::Base
  include Blacklight::BlacklightHelperBehavior
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  include FrequencySearchHelper
  include ActiveSupport::Rescuable
  include Hydra::Controller::ControllerBehavior

  FIXNUM_MAX = 2147483647
  CONCORDANCE_PRE_POST_CHUNK_SIZE = 7

  belongs_to :user
  attr_accessible :name, :id, :user_id, :shared

  validates :name, presence: true
  validates_length_of :name, :maximum => 255 , message:"Name is too long (maximum is 255 characters)"

  before_save :default_values
  #
  # Class variables for information about Solr
  #
  @@solr_config = nil
  @@solr = nil

  #
  # This variable are needed by Hydra Access Control
  #
  @current_user = nil
  @current_ability = nil


  # Indicate Hydra to add access control to the SOLR requests
  self.solr_search_params_logic += [:add_access_controls_to_solr_params]
  self.solr_search_params_logic += [:exclude_unwanted_models]

  def shared?
    return self.shared || false
  end

  #
  # This method set the item list as shared
  #
  def share
    self.shared=true
    self.save!
  end

  #
  # This method set the item list as not shared
  #
  def unshare
    self.shared=false
    self.save!
  end

  #
  # Get the documents ids from given search parameters
  #
  def getAllItemsFromSearch(search_params)
    get_solr_connection()

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
  # Get the list of Item handles which this ItemList contains.
  # Return an array of Strings.
  #
  def get_item_handles
    handles = ItemsInItemList.find_all_by_item_list_id(self.id).to_a.map {|aRecord| aRecord.item}
    return handles.sort
  end

  #
  # Query Solr for all the Solr Documents describing the constituent
  # Items of this ItemList.
  # Return the response we get from Solr.
  #
  def get_items(start, rows)
    get_solr_connection()

    rows = 20 if rows.nil?
    if start.nil?
      startValue = 0
    else
      startValue = (start.to_i-1)*rows.to_i
    end

    handles = get_item_handles()

    if (!handles.empty?)
      validItems = validateItems(handles)

      params = {:start => startValue, :rows => rows}
      document_list, response = SearchUtils.retrieveDocumentsFromSolr(params, handles)
    else
      response = {}
      response['response'] = {'numFound'=>0, 'start'=>0, 'docs'=>[]}
    end

    return response
  end
  
  #
  # Add some Items to this ItemList. The Items should be specified by
  # their ids. Don't add an Item which is already part of this ItemList.
  # Return a Set of the ids of the Items which were added.
  #
  def add_items(item_handles)
    get_solr_connection()

    bench_start = Time.now

    adding = Set.new(item_handles.map{ |item_handle| item_handle.to_s })
    adding.subtract(get_item_handles())

    # The variable adding now contains only the new ids

    verifiedItemHandles = []
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
        verifiedItemHandles << response['response']['docs'].first['handle']

      end
    }

    if (!verifiedItemHandles.empty?)
      recordsToInsert = []
      verifiedItemHandles.each do |anItemHandle|
        recordsToInsert << {item_list: self, item: anItemHandle}
      end
      ItemsInItemList.create(recordsToInsert)
    end

    bench_end = Time.now
    Rails.logger.debug("Time for adding #{adding.size} items to an item list: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)")
    profiler = ["Time for adding #{adding.size} items to an item list: (#{'%.1f' % ((bench_end.to_f - bench_start.to_f)*1000)}ms)"]

    return {addedItems: adding, profiler: profiler}
  end
  
  #
  #
  #
  def remove_items_by_handle(item_handles)
    item_handles = [item_handles] if item_handles.is_a?(String)

    recordsToRemove = ItemsInItemList.where("item_list_id=? AND item IN (?)", self.id, item_handles).to_a

    recordsToRemove.each do |aRecordToRemove|
      aRecordToRemove.destroy
    end

    recordsToRemove.size
  end

  #
  # Remove all Items from this ItemList.
  #
  def clear()
    return remove_items_by_handle(get_item_handles())
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

    handles = getItemsHandlesThatTheCurrentUserHasAccess()

    params = {}
    params[:q] = "{!qf=full_text pf=''}#{search_for}"
    params[:rows] = FIXNUM_MAX

    document_list, response = SearchUtils.retrieveDocumentsFromSolr(params, handles)

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
      result = ComplexFrequencySearch.new.executeFrequencySearchOnComplexTerm(query, facet, self)
    else
      result = SimpleFrequencySearch.new.executeFrequencySearchOnSimpleTerm(query, facet, self)
    end

    if (result.nil? || result.empty?)
      result = {:status => "NO_MATCHING_DOCUMENTS"}
    elsif (result[:status].nil?)
      result[:status] = "OK"
    end

    result
  end

  #
  # This method will return the list of item handles for which the current user
  # has at least read access rights.
  #
  def getItemsHandlesThatTheCurrentUserHasAccess
    validItems = []

    handles = get_item_handles()
    if (!handles.empty?)
      validItems = validateItems(handles)
    end

    validItems
  end

  #
  #
  #
  def setCurrentUser(currentUser)
    @current_user = currentUser
  end

  #
  #
  #
  def setCurrentAbility(currentAbility)
    @current_ability = currentAbility
  end

  private

  #
  # This method will filter the item handles for which the current user has no granted access
  #
  def validateItems (handles, batch_group =50)
    valids = []
    handles.in_groups_of(batch_group, false) do |groupOfItemsHandle|
      # create disjunction condition with the items Ids
      condition = groupOfItemsHandle.map{|itemHandle| "handle:\"#{itemHandle.gsub(":", "\:")}\""}.join(" OR ")

      params = {}
      params[:q] = condition
      params[:rows] = FIXNUM_MAX

      (response, document_list) = get_search_results params
      document_list.each do |aDoc|
        valids << aDoc[:handle]
      end
    end
    valids
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
  # Assign the default values for the unassigned properties
  #
  def default_values
    self.shared ||= false
    nil
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

  #
  # This method is required by  Hydra Access Control
  #
  def current_user
    @current_user
  end

  #
  # This method is required by  Hydra Access Control
  #
  def current_ability
    @current_ability
  end
end
