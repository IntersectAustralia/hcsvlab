
# Override the default jettywrapper tasks for clean and config
tasks = Rake.application.instance_variable_get '@tasks'
tasks.delete 'jetty:clean'
tasks.delete 'jetty:config'

namespace :jetty do 

	task :config => :environment do
		puts "HCS vLab jetty config task"

		system 'cp -vp fedora_conf/conf/development/fedora.fcfg jetty/fedora/default/server/config/'
		system 'cp -vp fedora_conf/conf/test/fedora.fcfg jetty/fedora/test/server/config/'

		system 'cp -vp solr_conf/conf/schema.xml jetty/solr/development-core/conf/'
		system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/development-AF-core/conf/'
		system 'cp -vp solr_conf/conf/schema.xml jetty/solr/test-core/conf/'
		system 'cp -vp solr_conf/conf/solrconfig.xml jetty/solr/test-AF-core/conf/'
	end

	task :clean => :environment do
		puts "HCS vLab jetty:clean task"

		system 'rake jetty:stop'
		system 'rm -rf jetty/'
		system 'git submodule init'
		system 'git submodule update'
	end

end