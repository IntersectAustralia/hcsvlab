# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ItemListsController < ApplicationController
  FIXNUM_MAX = 2147483647


  before_filter :authenticate_user!

  # Set itemList tab as current selected
  set_tab :itemList

  include Blacklight::Catalog

  def index
    retrieve_item_list_for_logged_user

    #@response = ItemList.new.get_items
    #@document_list = @response["response"]["docs"]
  end

  def show
    itemList = ItemList.find_by_id!(params[:id])

    @response = itemList.get_items(params[:page])
    @document_list = @response["response"]["docs"]

    render index
  end
  
  def create
    @itemList = ItemList.new(:name => params[:item_list][:name].strip, :user_id => current_user.id)
    if params[:all_items] == 'true'
      @documents = @itemList.getAllItemsFromSearch(params[:query_all_params])
    else
      @documents = params[:sel_document_ids].split(",")
    end
    if @itemList.save
      flash[:notice] = 'Item list created successfully'

      add_item_to_item_list(@itemList, @documents)

      redirect_to item_list_path(@itemList)
    end
  end

  def add_to_item_list
    itemList = ItemList.find_by_id(params[:itemListId])
    if params[:add_all_items] == "true"
      documents = itemList.getAllItemsFromSearch(params[:query_params])
    else
      documents = params[:document_ids].split(",")
    end

    added_set = add_item_to_item_list(itemList, documents)
    flash[:notice] = "#{added_set.size} Item#{added_set.size==1? '': 's'} added to item list #{itemList.name}"
    redirect_to item_list_path(itemList)
  end

  def clear
    itemList = ItemList.find_by_id!(params[:id])
    removed_set = itemList.clear
    flash[:notice] = "#{removed_set.size} Item#{removed_set.size==1? '': 's'} cleared from item list #{itemList.name}"
    redirect_to item_list_path(itemList)
  end

  def destroy
    itemList = ItemList.find_by_id!(params[:id])
    name = itemList.name
    itemList.clear
    itemList.delete
    flash[:notice] = "Item list #{name} deleted successfully"
    redirect_to item_lists_path
  end

  def concordance_search
    retrieve_item_list_for_logged_user

    if params[:search_for].split.size > 1
      flash[:notice] = "Concordance search allows only one word for searching"
      return
    end

    params[:q] = 'full_text:' + params[:search_for]

    bench_start = Time.now
    @highlighting = processAndHighlightManually(7)
    #@highlighting = processAndHighlightWithSolr()
    Rails.logger.debug("Time for processing the concordance view: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
  end

  private

  def processAndHighlightManually(preAndPostChunkSize)
    searchPattern = /[^\w]*#{params[:search_for]}[^\w]*/i

    # Tells blacklight to call this method when it ends processing all the parameters that will be sent to solr
    self.solr_search_params_logic += [:add_solr_extra_filters]

    (@response, @document_list) = get_search_results

    # Get document full text
    highlighting = {}
    @document_list.each do |doc|
      full_text = doc[:full_text]
      highlighting[doc[:id]] = {:full_text => []}

      # Iterate over everything that matches with the search in case-insensitive mode
      matchingData = full_text.to_enum(:scan, searchPattern).map { Regexp.last_match }
      matchingData.each { |m|
      #full_text.match(searchPattern) {|m|
        # get the text preceding the match and extract the last 7 words
        pre = m.pre_match().split(" ").last(preAndPostChunkSize).join(" ")
        # get the text after the match and extract the first 7 words
        post = m.post_match().split(" ").first(preAndPostChunkSize).join(" ")

        # Add come color to the martching word
        text = m.to_s.gsub(/#{params[:search_for]}/i, "<span class='highlighting'>#{params[:search_for]}</span>")

        # join the processed text
        highlighting[doc[:id]][:full_text] << "<td class='leftColumn'>" + pre + "</td><td class='centerColumn'>" + text  + "</td><td class='rightColumn'>" +  post + "</td>"
      }
    end

    highlighting
  end

  def add_solr_extra_filters(solr_parameters, user_params)
    solr_parameters[:fq] = 'item_lists:' + params[:id]
    solr_parameters[:rows] = FIXNUM_MAX
  end

# I COMMENTED THIS CODE BECAUSE WE ARE STILL NOT SURE IF WE ARE GOING TO USE SOLR
# TO DO THE CONCORDANCE SEARCH O NOT. AFTER WE DECIDE THAT, THIS CODE COULD BE REMOVED
=begin
  #DEPRECATED
  def processAndHighlightWithSolr(preAndPostChunkSize)
    self.solr_search_params_logic += [:add_highlight_parameters_solr]

    params[:'hl.fl'] = 'full_text'
    params[:hl] = true
    params[:'hl.snippets'] = 30

    (@response, @document_list) = get_search_results

    pp = {}
    pre = @response[:responseHeader][:params][:'hl.simple.pre']
    post = @response[:responseHeader][:params][:'hl.simple.post']
    @highlighting = @response[:highlighting]

    @highlighting.each do |key, value|
      value.each do |key2, value2|
        pp = []
        value2.each do |hl|
          newHl = hl.split(pre)
          firstWords = (newHl[0].nil?)? "" : newHl[0].split().last(preAndPostChunkSize).join(" ")

          lastWords = (newHl[2].nil?)? "" : newHl[2].split().first(preAndPostChunkSize).join(" ")

          pp << firstWords + " " + "<span style='color:red'>#{params[:search_for]}</span>" + " " + lastWords
        end
        @highlighting[key][key2] = pp
      end
    end
  end

  #DEPRECATED
  def add_highlight_parameters_solr(solr_parameters, user_params)
    solr_parameters[:fq] = 'item_lists:' + params[:id]
    solr_parameters[:hl] = true
    solr_parameters[:'hl.useFastVectorHighlight'] = true
    solr_parameters[:'hl.fl'] = user_params[:'hl.fl']
    solr_parameters[:'hl.snippets'] = user_params[:'hl.snippets']
    #solr_parameters[:'hl.simple.pre'] = "<span style='color:red'>"
    #solr_parameters[:'hl.simple.post'] = "</span>"
    solr_parameters[:'hl.simple.pre'] = "ZZZ@@@ZZZ"
    solr_parameters[:'hl.simple.post'] = "ZZZ@@@ZZZ"
    solr_parameters[:'hl.bs.type'] = "SENTENCE" # valids: CHARACTER, WORD, SENTENCE and LINE
    solr_parameters[:'hl.fragmenter'] = "regex"
    solr_parameters[:'hl.regex.slop'] = 0.5
    #solr_parameters[:'hl.regex.pattern'] = "[^\.,;]\b\s[\.!\?]"
    solr_parameters[:'hl.fragsize'] = 500
    solr_parameters[:'hl.mergeContiguous'] = false
    #solr_parameters[:'hl.boundaryScanner'] = 'breakIterator'
    #solr_parameters[:'hl.bs.maxScan'] = 100
    #solr_parameters[:'hl.bs.language'] = "en"
    #solr_parameters[:'fragListBuilder'] = "single"

  end
=end

  def retrieve_item_list_for_logged_user
    @userItemLists = ItemList.where(:user_id => current_user.id)

    @userItemLists = [] if @userItemLists.nil?
  end

  def add_item_to_item_list(itemList, documents_ids)
    if (!itemList.nil?)
      itemList.add_items(documents_ids)
    end
  end

end