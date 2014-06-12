namespace :deploy do

  desc "Configure ActiveMQ"
  task :configure_activemq, :roles => :app do
    run "cp -p #{current_path}/activemq_conf/activemq.xml $ACTIVEMQ_HOME/conf/", :env => {'RAILS_ENV' => stage}
  end

  desc "Start ActiveMQ"
  task :start_activemq, :roles => :app do
    run "cd $ACTIVEMQ_HOME && nohup bin/activemq start > nohup_activemq.out 2>&1", :env => {'RAILS_ENV' => stage}
  end

  desc "Stop ActiveMQ"
  task :stop_activemq, :roles => :app, :on_error => :continue do
    run "cd $ACTIVEMQ_HOME && bin/activemq stop", :env => {'RAILS_ENV' => stage}
  end

end