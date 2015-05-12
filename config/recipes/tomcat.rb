namespace :deploy do
  desc "Configure Tomcat 6"
  task :configure_tomcat6, :roles => :app do
    run "cp -p #{current_path}/tomcat_conf/setenv.sh $CATALINA_HOME/bin/", :env => {'RAILS_ENV' => stage}
  end

  desc "Start the Tomcat 6 server"
  task :start_tomcat6, :roles => :app do
    run "cd ${CATALINA_HOME} && nohup bin/startup.sh > nohup_tomcat.out 2>&1", :env => {'RAILS_ENV' => stage}
  end

  desc "Stop the Tomcat 6 server"
  task :stop_tomcat6, :roles => :app do
    run "cd ${CATALINA_HOME} && bin/shutdown.sh", :env => {'RAILS_ENV' => stage}
  end

  desc "Restart the Tomcat 6 server"
  task  :restart_tomcat6, :roles => :app do
    stop_tomcat6
    start_tomcat6
  end

end