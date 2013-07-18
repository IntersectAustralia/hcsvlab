# Override the default jettywrapper tasks for clean and config
tasks = Rake.application.instance_variable_get '@tasks'
tasks.delete 'jetty:clean'
tasks.delete 'jetty:config'
tasks.delete 'jetty:start'

namespace :jetty do

  task :config => :environment do
    puts "HCS vLab jetty config task"

    system 'cp -vp fedora_conf/conf/development/fedora.fcfg jetty/fedora/default/server/config/'
    system 'cp -vp fedora_conf/conf/test/fedora.fcfg        jetty/fedora/test/server/config/'

    system 'cp -vp solr_conf/conf/schema.xml jetty/solr/development-core/conf/'
    system 'cp -vp solr_conf/conf/schema.xml jetty/solr/development-AF-core/conf/'
    system 'cp -vp solr_conf/conf/schema.xml jetty/solr/test-core/conf/'
    system 'cp -vp solr_conf/conf/schema.xml jetty/solr/test-AF-core/conf/'

    system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/development-core/conf/'
    system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/development-AF-core/conf/'
    system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/test-core/conf/'
    system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/test-AF-core/conf/'
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
    puts "Waiting for Fedora and Solr to be ready...".yellow
    sleep 30

    while !ping(Blacklight.solr_config[:url]) do
      sleep 5
    end
    puts "Fedora and Solr ready".green
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

