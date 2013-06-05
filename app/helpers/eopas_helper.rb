require 'open-uri'

module EopasHelper

  def eopas_viewable?(documents)
    media = false
    xml = nil
    transcription = nil
    documents.each do |document|
      uri = document[PURL::SOURCE]
      if uri.ends_with? 'ogg'
        media = true
      elsif uri.ends_with? 'xml'
        xml = uri
      end
    end
    if xml
      transcription = is_transcription? xml.to_str
    end
    media && transcription
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