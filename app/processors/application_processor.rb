class ApplicationProcessor < ActiveMessaging::Processor

  # Default on_error implementation - logs standard errors but keeps processing. Other exceptions are raised.
  # Have on_error throw ActiveMessaging::AbortMessageException when you want a message to be aborted/rolled back,
  # meaning that it can and should be retried (idempotency matters here).
  # Retry logic varies by broker - see individual adapter code and docs for how it will be treated
  def on_error(err)
    if (err.kind_of?(StandardError))
      logger.error "ApplicationProcessor::on_error: #{err.class.name} rescued:\n" + \
      err.message + "\n" + \
      "\t" + err.backtrace.join("\n\t")
    else
      logger.error "ApplicationProcessor::on_error: #{err.class.name} raised: " + err.message
      raise err
    end
  end

  def debug(from, message)
    logger.debug("[#{DateTime.now}], [#{from}], [DEBUG] #{message}")
  end

  def info(from, message)
    logger.info("[#{DateTime.now}], [#{from}], [INFO ] #{message}")
  end

  def warn(from, message)
    logger.warn("[#{DateTime.now}], [#{from}], [WARN ] #{message}")
  end

  def warning(from, message)
    warn(from, message)
  end

  def error(from, message)
    logger.error("[#{DateTime.now}], [#{from}], [ERROR] #{message}")
  end
end