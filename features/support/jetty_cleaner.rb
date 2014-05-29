require "#{Rails.root}/spec/support/jetty_helper"


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

Before do |scenario|
  if scenario.instance_of?(Cucumber::Ast::Scenario)
    shouldCleanBeforeScenario = scenario.feature_tags.tags.select{|t| "@ingest_qa_collections".eql? t.name.to_s}.empty?

    if (shouldCleanBeforeScenario)
      clear_jetty
      $alreadyIngested = false

    end
  else
    clear_jetty
  end
end

Before('@ingest_qa_collections') do
  if (!$alreadyIngested)
    ingest_test_collections
    $alreadyIngested = true
  end
end