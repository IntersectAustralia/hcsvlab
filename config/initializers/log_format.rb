class ActiveSupport::BufferedLogger
  def formatter=(formatter)
    @log.formatter = formatter
  end
end

class Formatter

  def call(severity, time, progname, msg)
    formatted_severity = sprintf("%-5s","#{severity}")

    formatted_time = time.strftime("%Y-%m-%d %H:%M:%S")

    "[#{formatted_time}] #{formatted_severity} #{msg.strip}\n"
  end

end

Rails.logger.formatter = Formatter.new