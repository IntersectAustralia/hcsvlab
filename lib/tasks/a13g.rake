namespace :a13g do

  task :start_pollers => :environment do
    puts "Starting Fedora Worker"
    system "nice -n 10  script/poller start -- process-group=fedora_group"

    sleep(1)

    puts "Starting Solr Worker"
    system "nice -n 19  script/poller start -- process-group=solr_group"
  end

  task :stop_pollers => :environment do
    puts "Stopping workers"
    system "nice -n 19  script/poller stop"
  end

end
