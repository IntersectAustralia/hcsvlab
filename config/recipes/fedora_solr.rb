namespace :deploy do
  desc "Configure Fedora"
  task :configure_fedora, :roles => :app do
    run "cp -p #{current_path}/fedora_conf/conf/#{stage}/fedora.fcfg $FEDORA_HOME/server/config/", :env => {'RAILS_ENV' => stage}
  end

  desc "Configure Solr"
  task :configure_solr, :roles => :app do
    run "cp -p #{current_path}/solr_conf/hcsvlab-solr.xml    $CATALINA_HOME/conf/Catalina/localhost/solr.xml", :env => {'RAILS_ENV' => stage}
    run "cp -p #{current_path}/solr_conf/conf/schema.xml     $SOLR_HOME/hcsvlab/solr/hcsvlab-core/conf/schema.xml", :env => {'RAILS_ENV' => stage}
    run "cp -p #{current_path}/solr_conf/conf/solrconfig.xml $SOLR_HOME/hcsvlab/solr/hcsvlab-core/conf/solrconfig.xml", :env => {'RAILS_ENV' => stage}
    run "cp -p #{current_path}/solr_conf/conf/schema.xml     $SOLR_HOME/hcsvlab/solr/hcsvlab-AF-core/conf/schema.xml", :env => {'RAILS_ENV' => stage}
    run "cp -p #{current_path}/solr_conf/conf/solrconfig.xml $SOLR_HOME/hcsvlab/solr/hcsvlab-AF-core/conf/solrconfig.xml", :env => {'RAILS_ENV' => stage}
  end

  desc "Update the HCS vLab Solr core"
  task :update_solr_core, :roles => :app do
    # Remove the existing core and webapp
    run "rm -rf $SOLR_HOME/hcsvlab", :env => {'RAILS_ENV' => stage}
    run "rm -rf $CATALINA_HOME/webapps/solr/", :env => {'RAILS_ENV' => stage}
    create_solr_core
  end

  desc "Create the HCS vLab Solr core"
  task :create_solr_core, :roles => :app do
    # Copy the jar files etc that Tomcat will need for Solr 4.3 logging
    run "cp -rp #{current_path}/solr_conf/lib/ext/* $CATALINA_HOME/lib/", :env => {'RAILS_ENV' => stage}
    # Copy the solr core diir
    run "cp -rp #{current_path}/solr_conf/hcsvlab $SOLR_HOME/", :env => {'RAILS_ENV' => stage}
    # Configure solr
    configure_solr
  end

  desc "Start the a13g pollers"
  task :start_a13g_pollers, :roles => :app do
    run "cd #{current_path} && nohup rake a13g:start_pollers > nohup_a13g_pollers.out 2>&1", :env => {'RAILS_ENV' => stage}
  end

  desc "Stop the a13g pollers"
  task :stop_a13g_pollers, :roles => :app do
    run "cd #{current_path} && rake a13g:stop_pollers", :env => {'RAILS_ENV' => stage}
  end

end