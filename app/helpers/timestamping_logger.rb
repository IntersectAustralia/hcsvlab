class TimestampingLogger
  # To change this template use File | Settings | File Templates.

  @logger

  def initialize(logger_to_wrap)
    @logger = logger_to_wrap
  end

  def debug(message)
    @logger.tagged(DateTime.now, "debug") { @logger.debug(message) }
  end

  def info(message)
    @logger.tagged(DateTime.now, "Info") { @logger.info(message) }
  end

  # required for request_exception_handler gem
  def info?
    return true
  end

  def warn(message)
    @logger.tagged(DateTime.now, "Warning") { @logger.warn(message) }
  end

  def warning(message)
    warn(message)
  end

  def error(message)
    @logger.tagged(DateTime.now, "ERROR") { @logger.error(message) }
  end

  def fatal(message)
    @logger.tagged(DateTime.now, "** FATAL **") { @logger.fatal(message) }
  end

  def log_backtrace(e)
    @logger.tagged(DateTime.now, "backtrace") { @logger.info("#{e.message}\n\t#{e.backtrace.join("\n\t")}")}
  end
end