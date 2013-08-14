def clear_jetty
  # clear Solr
  uri = URI.parse(Blacklight.solr_config[:url] + '/update?commit=true')

  req = Net::HTTP::Post.new(uri)
  req.body = '<delete><query>*:*</query></delete>'

  req.content_type = "text/xml; charset=utf-8"
  req.body.force_encoding("UTF-8")
  res = Net::HTTP.start(uri.hostname, uri.port) do |http|
    http.request(req)
  end

  # clear Fedora
  Item.delete_all
  Document.delete_all
  Collection.delete_all
  CollectionList.delete_all
  Licence.delete_all

end

# Reserve first 10 for Item testing
def reserve_fedora_pids
  (1..10).each do |num|
    Item.create(pid: "hcsvlab:#{num}")
  end
end

#make sure jetty is started and clean
puts 'Ensuring jetty test instance is up...'.yellow
if Dir.glob("#{Rails.root}/tmp/pids/*jetty.pid").empty?
  puts "fedora.pid file not found. Make sure hydra-jetty is installed and the #{Rails.env} copy is installed and running".red
  exit 1
end

#make sure jetty is set up properly
output = `diff #{Rails.root}/fedora_conf/conf/test/fedora.fcfg #{Rails.root}/jetty/fedora/test/server/config/fedora.fcfg`
if output.present?
  puts "Please run rake jetty:config to set up Fedora".red
  puts output
  exit 1
end
puts 'Test jetty ready'.green

`echo '' > #{Rails.root}/log/test.log`
clear_jetty

reserve_fedora_pids

at_exit do
  clear_jetty
end

Before do
  clear_jetty
  
end

