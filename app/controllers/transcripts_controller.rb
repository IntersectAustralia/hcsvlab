require 'blacklight/catalog'
require 'open-uri'
require 'ostruct'

class TranscriptsController < ApplicationController

  respond_to :html, :xml

  include Blacklight::Catalog
  include Blacklight::BlacklightHelperBehavior

  before_filter :authenticate_user!

  MEDIA_ITEM_FIELDS = %w(title description recorded_on copyright license format media depositor)
  TRANSCRIPT_FIELDS = %w(title date depositor country_code language_code copyright license private 
      source source_cache transcript_format participants_attributes description format recorded_on)

  def show
    attributes = document_to_attribues params['id'] 
    @transcript = load_transcript attributes
    @media_item = load_media attributes
    logger.warn "Test: {@media_item.inspect}"
  end

  def load_transcript(attributes)
    data = open(attributes['transcription']).read.force_encoding('UTF-8')
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
    # media = get_media(params['type'], params['url'])
    media = get_media(attributes['format'], params['url'])
    attributes['media'] = media
    attributes = filter_attributes(attributes, MEDIA_ITEM_FIELDS)
    media_item = MediaItem.new attributes
    puts attributes
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

  def get_media(type, url)
    media = OpenStruct.new
    if type == 'audio'
      audio = OpenStruct.new
      audio.url = url
      media.audio = audio
    elsif type == 'video'
      video = OpenStruct.new
      video.url = url
      media.video = video
      poster = OpenStruct.new
      poster.url = ''
      media.poster = poster
    end
    media
  end

  def detect_format(data)
    result = nil
    flattened = data.downcase
    if flattened.include? '<time_slot'  
      result = 'elan'
    elsif flattened.include? '<txgroup'
      result = 'toolbox'
    elsif flattened.include? '<sync'
      result = 'transciber'
    elsif flattened.include? '<eopas'
      result = 'eopas'
    end
    result
  end

  def find_transcription(attributes)
    result = ''
    # HACK: this should really find the document via dc:source
    attributes['document'].each do |filename|  
      if File.extname(filename) == '.xml'
        result = "http://#{request.host}:8080/#{attributes['isPartOf']}/#{filename}"
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
    attributes['format'] = 'video'

    attributes['recorded_on'] = attributes['created']
    attributes['copyright'] = attributes['rights']
    attributes['license'] = attributes['rights']

    depositor = OpenStruct.new
    depositor.full_name = attributes['depositor']
    attributes['depositor'] = depositor
    attributes['transcription'] = find_transcription attributes

    attributes
  end

end
