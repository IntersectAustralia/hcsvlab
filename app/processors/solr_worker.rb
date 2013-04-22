#
# Solr_Worker
#
class Solr_Worker < ApplicationProcessor

  subscribes_to :solr_worker

  def on_message(message)
    logger.debug "Solr_Worker received: " + message
  end

end

