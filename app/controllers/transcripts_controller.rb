require 'blacklight/catalog'
require 'open-uri'
require 'ostruct'

class TranscriptsController < ApplicationController

  respond_to :html, :xml

  include Blacklight::Catalog
  include Blacklight::BlacklightHelperBehavior
  include EopasHelper

  before_filter :authenticate_user!

  MEDIA_ITEM_FIELDS = %w(title description recorded_on copyright license format media depositor)
  TRANSCRIPT_FIELDS = %w(title date depositor country_code language_code copyright license private
      source source_cache transcript_format participants_attributes description format recorded_on)

  FEDORA_CONFIG = YAML.load_file("#{Rails.root.to_s}/config/fedora.yml")[Rails.env] unless const_defined?(:FEDORA_CONFIG)
  
  def show
    attributes = document_to_attribues params['id']
    @transcript = load_transcript attributes
    @media_item = load_media attributes
  end

  def load_transcript(attributes)
    puts "Trans: #{attributes['transcription']}"
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
      audio.url = FEDORA_CONFIG["url"].to_s + "/objects/#{doc.pid}/datastreams/CONTENT1/content"
      media.audio = audio
    elsif type == 'video'
      video = OpenStruct.new
      video.url = FEDORA_CONFIG["url"].to_s + "/objects/#{doc.pid}/datastreams/CONTENT1/content"
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

  def document_to_attribues(item_id)
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

end
