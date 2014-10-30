require 'blacklight/catalog'
require 'open-uri'
require 'ostruct'

class TranscriptsController < ApplicationController

  respond_to :html, :xml

  include Blacklight::Catalog
  include Blacklight::BlacklightHelperBehavior
  include EopasHelper

  prepend_before_filter :retrieve_and_set_item_id
  before_filter :authenticate_user!

  MEDIA_ITEM_FIELDS = %w(title description recorded_on copyright license format media depositor)
  TRANSCRIPT_FIELDS = %w(title date depositor country_code language_code copyright license private
      source source_cache transcript_format participants_attributes description format recorded_on)

  def show
    begin
      attributes = document_to_attributes params['id']
      @transcript = load_transcript attributes
      @media_item = load_media attributes
    rescue Exception => e
      Rails.logger.error(e.backtrace)
      flash[:error] = "Sorry, you have requested a record that doesn't exist."
      redirect_to root_url and return
    end
  end

  def load_transcript(attributes)
    doc = attributes['transcription']
    #data = open(attributes['transcription']).read.force_encoding('UTF-8')
    data = doc.datastreams['CONTENT1'].content
    file_format = detect_format data

    attributes = filter_attributes(attributes, TRANSCRIPT_FIELDS)

    transcript = Transcript.new attributes
    transcript.create_transcription(data, file_format)
    transcript
  end

  def get_solr_document(item_id)
    documents = get_solr_response_for_doc_id(item_id)[0]
    document = documents['response']['docs'][0]

    document
  end

  def load_media(attributes)
    # TODO change this to allow other formats
    doc = find_doc_by_extension('ogg')
    attributes['format'] = detect_media_format doc.datastreams['CONTENT1'].content
    media = get_media(attributes['format'], doc)
    attributes['media'] = media
    attributes = filter_attributes(attributes, MEDIA_ITEM_FIELDS)
    media_item = MediaItem.new attributes
    media_item
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

  def get_media(type, doc)
    # TODO: Can we make the media player work with the data rather than a url to Fedora?
    media = OpenStruct.new
    if type == 'audio'
      audio = OpenStruct.new
      audio.url = UrlHelper::getDocumentUrl(doc)
      media.audio = audio
    elsif type == 'video'
      video = OpenStruct.new
      video.url = UrlHelper::getDocumentUrl(doc)
      media.video = video
      poster = OpenStruct.new
      poster.url = ''
      media.poster = poster
    end
    media
  end

  def find_doc_by_extension(ext)
    # FIX: document is opened multiple times, this could be reduced to one time
    item = Item.find(params[:id])
    documents = item.documents
    #documents = item_documents_from_id(params['id'], [MetadataHelper::SOURCE])
    result = nil
    documents.each do |document|
      #uri = document[MetadataHelper::SOURCE]
      if document.file_name[0].ends_with? ext
        result = document
        break
      end
    end
    result
  end

  def filter_attributes(attributes, filter)
    attributes.select {|key, value| filter.include? key}
  end

  def document_to_attributes(item_id)
    document = get_solr_document item_id
    attributes = solr_doc_to_hash(document)

    attributes['recorded_on'] = attributes['created']
    attributes['copyright'] = attributes['rights']
    attributes['license'] = attributes['rights']

    depositor = OpenStruct.new
    depositor.full_name = attributes['depositor']
    attributes['depositor'] = depositor
    attributes['transcription'] = find_doc_by_extension 'xml'

    attributes
  end

  private

  #
  #
  #
  def retrieve_and_set_item_id
    handle = nil
    handle = "#{params[:collection]}:#{params[:itemId]}" if params[:collection].present? and params[:itemId].present?

    if handle
      item = Item.find_by_handle(handle)
      if item.nil?
        respond_to do |format|
          format.html {resource_not_found(Blacklight::Exceptions::InvalidSolrID.new("Sorry, you have requested a record that doesn't exist.")) and return}
          format.any { render :json => {:error => "not-found"}.to_json, :status => 404 and return}
        end
      end
      params[:id] = item.first.id
    end
  end

end
