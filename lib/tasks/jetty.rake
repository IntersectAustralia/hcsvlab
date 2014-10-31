# Override the default jettywrapper tasks for clean and config
tasks = Rake.application.instance_variable_get '@tasks'
tasks.delete 'jetty:clean'
tasks.delete 'jetty:config'
tasks.delete 'jetty:start'

namespace :jetty do

  task :reset_all do
    Rake::Task['a13g:stop_pollers'].invoke
    Rake::Task['jetty:stop'].invoke
    Rake::Task['jetty:clean'].invoke
    Rake::Task['jetty:config'].invoke
    Rake::Task['jetty:start'].invoke
    Rake::Task['a13g:start_pollers'].invoke
  end

  task :config => :environment do
    puts "Alveo jetty config task"


    system 'cp -vp solr_conf/conf/schema.xml jetty/solr/development-core/conf/'
    system 'cp -vp solr_conf/conf/schema.xml jetty/solr/test-core/conf/'

    system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/development-core/conf/'
    system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/test-core/conf/'

    # Adds OpenRDF Sesame into jetty.
    system 'cp -vp sesame_bin/openrdf-sesame.war jetty/webapps/'
    system 'cp -vp sesame_bin/openrdf-workbench.war jetty/webapps/'
  end

  task :clean => :environment do
    puts "HCS vLab jetty:clean task"
    system 'rake jetty:stop'
    system 'rm -rf jetty/'
    system 'git submodule init'
    system 'git submodule update'
  end

  desc "Start jetty"
  task :start => :environment do
    Jettywrapper.start(JETTY_CONFIG)
    puts "jetty started at PID #{Jettywrapper.pid(JETTY_CONFIG)}"
    puts "Waiting for Solr and Sesame to be ready...".yellow
    sleep 30

    while !ping(Blacklight.solr_config[:url]) do
      sleep 5
    end
    puts "Solr and Sesame are ready".green
  end

end

require 'timeout'

def ping(host)
  begin
    Timeout.timeout(5) do
      res = Net::HTTP.get(URI(host))
      return true
    end
  rescue Errno::ECONNREFUSED
    return false
  rescue Timeout::Error
    return false
  end
end

