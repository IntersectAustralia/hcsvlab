require 'open-uri'
# require 'mimemagic'

module EopasHelper

  def eopas_viewable?(id)
    Rails.logger.debug("Checking if #{id.to_s} is viewable in EOPAS")
    media = false
    transcription = nil
    doc_count = 0
    media_count = 0


    # This code is consuming a lot of memory since is loading the whole content of each document
    # in memory just to decide the mimeType of it. Following some changes I would do to this code:

    # 2) Instead of loading the content in memory to detect the mimeType, we could use this line:
    #     mimeType = document.mime_type.first
    # 3) Finally, given the mimeType we need to check whether it is Audio or Video.
    #
    # 4) In the case of the transcript file, we need to load the content in memory to decide which type of
    #    transcript are we using, but that is not a problem, in general are very small text files.

    item = Item.find(id)
    item.documents.each do |document|
      file_name = document.file_name[0]
      next if file_name.nil?
      begin
        doc_content = document.datastreams['CONTENT1'].content
        if file_name.ends_with? 'xml'
          transcription = is_transcription? doc_content
          doc_count += 1
        else
          media_format = detect_media_format doc_content
          if media_format == 'audio' or media_format == 'video'
            media = true
            media_count += 1
          end
        end
      rescue Exception => msg
        Rails.logger.warn("Error reading document content: #{msg}")
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

  #
  # Return a message when the browser cannot play the Audio or video file
  #
  def showMessageIfCannotPlayFile(file)
    message = ""
    myBrowser = (request.env['HTTP_USER_AGENT'].nil?)?"":request.env['HTTP_USER_AGENT']

    if (myBrowser.include?("Safari") and !myBrowser.include?("Chrome"))
      if (file.to_s.downcase.end_with?(".ogg"))
        message = "OGG media files may not play in Safari. Please try another browser or download the media."
      elsif (file.to_s.downcase.end_with?(".webm"))
        message = "WebM media files may not play in Safari. Please try another browser or download the media."
      end
    elsif (myBrowser.include?("Firefox"))
      if (file.to_s.downcase.end_with?(".mp3"))
        message = "MP3 media files may not play in Firefox. Please try another browser or download the media."
      elsif (file.to_s.downcase.end_with?(".mp4"))
        message = "MP4 media files may not play in Firefox. Please try another browser or download the media."
      end
    elsif (myBrowser.include?("MSIE"))
      if (file.to_s.downcase.end_with?(".ogg"))
        message = "OGG media files may not play in Internet Explorer. Please try another browser or download the media."
      elsif (file.to_s.downcase.end_with?(".wav"))
          message = "WAV media files may not play in Internet Explorer. Please try another browser or download the media."
      elsif (file.to_s.downcase.end_with?(".webm"))
        message = "WebM media files may not play in Internet Explorer. Please try another browser or download the media."
      end
    elsif (myBrowser.include?("Opera"))
      if (file.to_s.downcase.end_with?(".mp3"))
        message = "MP3 media files may not play in Opera. Please try another browser or download the media."
      elsif (file.to_s.downcase.end_with?(".mp3"))
        message = "MP4 media files may not play in Opera. Please try another browser or download the media."
      end
    end
    message
  end
end