#
# Add your destination definitions here
# can also be used to configure filters, and processor groups
#
ActiveMessaging::Gateway.define do |s|
  #s.destination :orders, '/queue/Orders'
  #s.filter :some_filter, :only=>:orders
  #s.processor_group :group1, :order_processor
 
  s.destination :fedora_update, '/queue/fedora.apim.update'
  s.destination :fedora_access, '/queue/fedora.apim.access'
 
  s.destination :solr_worker, '/queue/hcsvlab.solr.worker'
 
end
