require 'blacklight/catalog'

require 'ostruct'

class MediaItemsController < ApplicationController

  respond_to :html

  include Blacklight::Catalog
  include Blacklight::BlacklightHelperBehavior

  def show
    document = get_solr_response_for_doc_id(params['id'])[0]
    document = document['response']['docs'][0]

    media = get_document_url params['id']
    document = solr_doc_to_hash(document)   
    document['media'] = media

    logger.warn "Test: #{document}"


    @media_item = MediaItem.new document
    
    file = OpenStruct.new
    file.path = '/Users/ilya/workspace/Downloads/eoaps.xml'
    source = OpenStruct.new
    source.file = file
    params = {source: source, transcript_format: 'EOPAS', depositor: 'Steve', title: 'Test', date: '2000-04-07 00:00:00 UTC', country_code: 'AU', language_code: 'eng'}
    # @transcripts = [Transcript.new(params)]
    @transcripts = []
    # logger.warn "Test: #{@media_item.media.video.url}"
    logger.warn "Test: #{@transcripts.inspect}"
  end


  def solr_doc_to_hash(solr_document)
    result = {}
    solr_document.each do |key, value|
      key = key.split('/')[-1].split('#')[-1].split('_')[0..-2].join('_')
      value = value[0] unless value.size > 1
      result[key] = value
    end
    result
  end

  def get_document_url document_id
    uris = [PURL::TYPE, PURL::SOURCE]
    # logger.warn "#Test: #{document[PURL::TYPE.to_s + "_tesim"]}"
    # document[PURL::TYPE.to_s + "_tesim"].each { |t| type = t unless t == "Original" or t == "Raw" }
    media = OpenStruct.new
    item_documents(document_id, uris).each do |values|
      # logger.warn "Test: #{values}"
      if values[PURL::TYPE] = 'Video'
        video = OpenStruct.new
        video.url = values[PURL::SOURCE].to_s
        media.video = video
        poster = OpenStruct.new
        poster.url = 'http://konstantkitten.com/wp-content/uploads/kittne4.jpg'
        media.poster = poster
      end
    end
    media
  end

end
