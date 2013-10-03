#
# Consumer for all otherwise un-subscribed queues intended to stop vast swathes
# of unread meassages from hanging around in the system making it look untidy.
#
class VacuumCleaner < ApplicationProcessor

  subscribes_to :fedora_access

  @@count = 0
 
  def on_message(message)
    @@count = @@count + 1
    logger.debug "Vacuum_Cleaner cleaned #{@@count} messages" if @@count % 100000 == 0
  end

end
