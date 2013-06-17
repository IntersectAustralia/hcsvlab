require 'open-uri'
# require 'mimemagic'

module EopasHelper

  def eopas_viewable?(documents)
    media = false
    xml = nil
    transcription = nil
    doc_count = 0
    media_count = 0
    documents.each do |document|
      uri = document[MetadataHelper::SOURCE]
      if uri.ends_with? 'xml'
        xml = uri
        doc_count += 1
      else
        media_format = detect_media_format uri
        if media_format == 'audio' or media_format == 'video'
          media = true
          media_count += 1
        end
      end
    end
    if xml
      transcription = is_transcription? xml.to_str
    end
    media && transcription && media_count == 1 && doc_count == 1
  end

  def is_transcription?(url)
    # NOTE: Will return false if URL is unavailable
    begin
      uri = URI.parse(url)
      data = uri.read
      transcription = detect_format data
    rescue
      transcription = nil
    end
    transcription
  end

  def detect_media_format(url)
    type = nil
    begin
      data = open url
      puts url
      # NOTE: This will result in performance issues over a network
      mimetype = MimeMagic.by_magic(data)
      if mimetype.type == 'application/ogg'
        type = 'video'
      else
        type = mimetype.mediatype
      end
    rescue
    end
    type
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

end