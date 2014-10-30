require "#{Rails.root}/spec/support/jetty_helper"


#make sure jetty is started and clean
puts 'Ensuring jetty test instance is up...'.yellow
if Dir.glob("#{Rails.root}/tmp/pids/*jetty.pid").empty?
  puts "jetty.pid file not found. Make sure hydra-jetty is installed and the #{Rails.env} copy is installed and running".red
  exit 1
end

#make sure jetty is set up properly

output = `diff #{Rails.root}/solr_conf/conf/schema.xml #{Rails.root}/jetty/solr/development-core/conf/schema.xml`
if output.present?
  puts "Please run rake jetty:config to set up Solr".red
  puts output
  exit 1
end
puts 'Test jetty ready'.green

`echo '' > #{Rails.root}/log/test.log`
clear_jetty

at_exit do
  clear_jetty
end

Before do |scenario|
  clear_jetty
  if scenario.instance_of?(Cucumber::Ast::Scenario)
    if scenario.feature_tags.tags.collect(&:name).include?("@ingest_qa_collections")
      ingest_test_collections
    end
  end
end
