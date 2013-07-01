# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ItemListsController < ApplicationController
  include Blacklight::Catalog
  include Blacklight::BlacklightHelperBehavior
  
  FIXNUM_MAX = 2147483647

  before_filter :authenticate_user!
  load_and_authorize_resource

  # Set itemList tab as current selected
  set_tab :itemList

  def index
  end

  def show
    @response = @item_list.get_items(params[:page], params[:per_page])
    @document_list = @response["response"]["docs"]
    respond_to do |format|
      format.json
      format.html { render :index }
    end
    
  end
  
  def create
    if params[:all_items] == 'true'
      documents = @item_list.getAllItemsFromSearch(params[:query_all_params])
    else
      documents = params[:sel_document_ids].split(",")
    end
    if @item_list.save
      flash[:notice] = 'Item list created successfully'
      add_item_to_item_list(@item_list, documents)
      redirect_to @item_list
    end
  end

  def add_items
    if params[:add_all_items] == "true"
      documents = @item_list.getAllItemsFromSearch(params[:query_params])
    else
      documents = params[:document_ids].split(",")
    end

    added_set = add_item_to_item_list(@item_list, documents)
    flash[:notice] = "#{view_context.pluralize(added_set.size, "")} added to item list #{@item_list.name}"
    redirect_to @item_list
  end

  def clear
    bench_start = Time.now

    removed_set = @item_list.clear

    Rails.logger.debug("Time for clear item list: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    flash[:notice] = "#{view_context.pluralize(removed_set.size, "")} cleared from item list #{@item_list.name}"
    redirect_to @item_list
  end

  def destroy
    bench_start = Time.now

    name = @item_list.name
    @item_list.clear
    @item_list.delete

    Rails.logger.debug("Time for deleting an Item list: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

    flash[:notice] = "Item list #{name} deleted successfully"
    redirect_to item_lists_path
  end

  def concordance_search
    if params[:search_for].split.size > 1
      flash[:notice] = "Concordance search allows only one word for searching"
      return
    end

    # do matching only in the text. search for "dog," results in "dog", but search for "dog-fighter" results in "dog-fighter"
    search_for = params[:search_for].match(/(\w+([-]?\w+)?)/i).to_s
    params[:q] = 'full_text:"' + search_for + '"'

    bench_start = Time.now

    # Tells blacklight to call this method when it ends processing all the parameters that will be sent to solr
    self.solr_search_params_logic += [:add_concordance_solr_extra_filters]

    # get search result from solr
    (@response, @document_list) = get_search_results

    #process the information
    @highlighting = processAndHighlightManually(@document_list, search_for, 7)

    Rails.logger.debug("Time for searching for '#{search_for}' in concordance view: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")

  end

  def frequency_search
    @facet_field = params[:facet]
    search_for = params[:search_for].match(/(\w+([-]?\w+)?)/i).to_s

    params[:q] = 'full_text:"' + search_for + '"'

    bench_start = Time.now
    # Tells blacklight to call this method when it ends processing all the parameters that will be sent to solr
    self.solr_search_params_logic += [:add_frequency_solr_extra_filters]

    # get search result from solr
    (@response, @document_list) = get_search_results
    facet_fields = @response[:facet_counts][:facet_fields]

    #process the information
    @result = doFrequencySearch(facet_fields, @document_list, search_for, @facet_field)

    Rails.logger.debug("Time for processing the frequency view: (#{'%.1f' % ((Time.now.to_f - bench_start.to_f)*1000)}ms)")
  end

  private

  def doFrequencySearch(facet_fields, document_list, search_for, facet_field_restriction)

    searchPattern = /(^|\W)(#{search_for})(\W|$)/i

    facetsWithResults = facet_fields[facet_field_restriction]

    # First I will obtain the facets and the number of documents matching with each one
    result = {}
    i = 0
    while (i < facetsWithResults.size) do
      # Blacklight returns the facets setting the name of the facet in the even numbers, and the
      # number of document for that facet in the next index.
      facetValue = facetsWithResults[i]
      facetNumDocs = facetsWithResults[i+1]

      result[facetValue] = {:num_docs => facetNumDocs, :num_occurrences => 0}

      i = i + 2
    end

    # Second I will count the number of matches in each document.
    document_list.each do |doc|
      full_text = doc[:full_text]
      matchingData = full_text.to_enum(:scan, searchPattern).map { Regexp.last_match }
      facetValue = doc[facet_field_restriction]
      if (!facetValue.nil?)
        facetValue.each do |facet|
          # If for some reason the facet is not in the Hash, I won't make the process fail, but
          # I will show the text "###" in the number of documents. This should not happen.
          if (result[facet].nil?)
            result[facet] = {:num_docs => "###", :num_occurrences => 0}
          end
          result[facet][:num_occurrences] = result[facet][:num_occurrences] + matchingData.size
        end
      end
    end

    result
  end

  def add_frequency_solr_extra_filters(solr_parameters, user_params)
    solr_parameters[:fq] = 'item_lists:' + params[:id]
    solr_parameters[:rows] = FIXNUM_MAX
    solr_parameters[:facet] = "on"
    solr_parameters[:'facet.field'] = @facet_field
    solr_parameters[:'facet.limit'] = -1
  end

  def processAndHighlightManually(document_list, search_for, preAndPostChunkSize)
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
        pre = pre[-[pre.size, charactersChunkSize].min,charactersChunkSize].split(" ").last(preAndPostChunkSize).join(" ")

        # get the text after the match and extract the first 7 words
        post = m.post_match()[0,charactersChunkSize].split(" ").first(preAndPostChunkSize).join(" ")

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

  def add_concordance_solr_extra_filters(solr_parameters, user_params)
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

  def add_item_to_item_list(item_list, documents_ids)
    item_list.add_items(documents_ids) unless item_list.nil?
  end

end