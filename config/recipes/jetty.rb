namespace :deploy do
  desc "Start the jetty server"
  task :start_jetty, :roles => :app do
    run "cd #{current_path} && rake jetty:config", :env => {'RAILS_ENV' => stage}
    run "cd #{current_path} && nohup rake jetty:start > nohup_jetty.out 2>&1", :env => {'RAILS_ENV' => stage}
  end

  desc "Stop the jetty server"
  task :stop_jetty, :roles => :app do
    run "cd #{current_path} && rake jetty:stop", :env => {'RAILS_ENV' => stage}
  end
end