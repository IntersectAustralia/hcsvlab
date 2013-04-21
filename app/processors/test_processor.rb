class TestProcessor < ApplicationProcessor

  subscribes_to :fedora_update
  subscribes_to :fedora_access

  def on_message(message)
    logger.debug "TestProcessor received: " + message
  end
end