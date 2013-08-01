require 'open-uri'
# require 'mimemagic'

module EopasHelper

  def eopas_viewable?(id)
    Rails.logger.debug("Checking if #{id.to_s} is viewable in EOPAS")
    media = false
    transcription = nil
    doc_count = 0
    media_count = 0
    item = Item.find(id)
    item.documents.each do |document|
      file_name = document.file_name[0]
      next if file_name.nil?
      if file_name.ends_with? 'xml'
        transcription = is_transcription? document.datastreams['CONTENT1'].content
        doc_count += 1
      else
        media_format = detect_media_format document.datastreams['CONTENT1'].content
        if media_format == 'audio' or media_format == 'video'
          media = true
          media_count += 1
        end
      end
    end
    Rails.logger.debug("#{id.to_s}: media= #{media} transcription= #{transcription} media_count= #{media_count} doc_count=#{doc_count}")
    media && transcription && media_count == 1 && doc_count == 1
  end

  def is_transcription?(data)
    # NOTE: Will return false if URL is unavailable
    begin
      transcription = detect_format data
    rescue
      Rails.logger.warn("Exception detecting transcription")
      transcription = nil
    end
    transcription
  end

  def detect_media_format(data)
    type = nil
    begin
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