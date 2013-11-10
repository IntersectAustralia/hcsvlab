class WARCWriter

  def initialize(filename)
    logger.debug "Opening a WARCWriter on #{filename}"
    @version  = "0.18"
    @timestamp = DateTime.now.iso8601
    @filename = filename
    @stream   = File.open(filename, "w")
  end

  def close()
    logger.debug "Closing the WARCWriter on #{@filename}"
    @stream.close unless @stream.nil?
    @stream = nil
  end

  def add_warcinfo(uri, info)
    puts "WARC/#{@version}"
    puts "WARC-Type: warcinfo"
    puts "WARC-Date: #{@timestamp}"
    puts "WARC-Record-ID: #{uri}"
    puts "Content-Type: application/warc-fields"
    puts "Content-Length: #{info.length}"
    puts ""
    puts info
    puts ""
  end

  def add_record_from_string(header_hash, contents)
    puts "WARC/#{@version}"
    puts "WARC-Date: #{@timestamp}"
    header_hash.each_pair { |k, v| puts "#{k}: #{v}" }
    puts "Content-Type: application/warc-fields"
    puts "Content-Length: #{contents.length}"
    puts ""
    puts contents
    puts ""
  end

  def add_record_from_stream(header_hash, stream)
    puts "WARC/#{@version}"
    puts "WARC-Date: #{@timestamp}"
    header_hash.each_pair { |k, v| puts "#{k}: #{v}" }
    puts "Content-Type: application/warc-fields"
    puts "Content-Length: #{stream.size}"
    puts ""
    line = stream.gets
    while line != nil
      puts line
      line = stream.gets
    end
    puts ""
  end

  def add_record_from_file(header_hash, filename)
    File.open(filename, "r") { |stream| add_record_from_stream(header_hash, stream)}
  end

  def puts(string)
    @stream.puts string
  end
end