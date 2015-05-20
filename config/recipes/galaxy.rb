namespace :deploy do
  desc "Configure Galaxy"
  task :configure_galaxy, :roles => :galaxy do
    run "sed -i 's+__HCSVLAB_APP_URL__+#{server_url}+g' $GALAXY_HOME/universe_wsgi.ini"
    run "sed -i 's+__GALAXY_PORT__+#{galaxy_port}+g' $GALAXY_HOME/universe_wsgi.ini"
    run "sed -i 's+__TOOL_SHED_URL__+#{galaxy_url + ':' + toolshed_port}+g' $GALAXY_HOME/tool_sheds_conf.xml"
    run "sed -i 's+__HCSVLAB_GA_TRACKER_ID__+#{galaxy_ga_tracker_id}+g' $GALAXY_HOME/universe_wsgi.ini"
    run "sed -i 's+__HCSVLAB_SMTP_SERVER__+#{galaxy_smtp_server}+g' $GALAXY_HOME/universe_wsgi.ini"
  end

  desc "Update galaxy"
  task :update_galaxy, :roles => :galaxy do

    # First show the branches and tags to decide from where are we going to deploy
    require 'colorize'
    default_tag = 'HEAD'
    run "cd $GALAXY_HOME && #{try_sudo} git fetch --all"
    availableLocalBranches = capture("cd $GALAXY_HOME && git branch").split (/\r?\n/)
    availableLocalBranches.map! { |s|  "(local) " + s.strip}

    availableRemoteBranches = capture("cd $GALAXY_HOME && git branch -r").split (/\r?\n/)
    availableRemoteBranches.map! { |s|  "(remote) " + s.split('/')[-1].strip}

    availableTags = capture("cd $GALAXY_HOME && git tag").split (/\r?\n/)

    puts "Availible tags:".colorize(:yellow)
    availableTags.each {|s| puts s}
    puts "Availible branches:".colorize(:yellow)
    availableLocalBranches.each {|s| puts s}
    availableRemoteBranches.each {|s| puts s.colorize(:red)}

    tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the branch/tag first) or HEAD?: [#{default_tag}] ".colorize(:yellow)
    tag = default_tag if tag.empty?

    puts "Deploying brach/tag: #{tag}".colorize(:red)


    # Once we chose the branch/tag, we setup up it in the local repository.
    run "cd $GALAXY_HOME && #{try_sudo} git fetch --all"
    run "cd $GALAXY_HOME && #{try_sudo} git reset --hard #{tag}"

  end

  desc "Redeploy Galaxy, stops, updates, configures and starts galaxy"
  task :redeploy_galaxy, :roles => :galaxy do
    set(:user) { "galaxy" }
    set :default_shell, '/bin/bash'
    update_galaxy
    configure_galaxy
    restart_galaxy
    redeploy_galaxy_toolshed
  end

  desc "Start Galaxy Toolshed"
  task :start_galaxy_toolshed, :roles => :galaxy do
    run "cd $GALAXY_HOME && #{try_sudo} service toolshed start", :env => {'RAILS_ENV' => stage}
  end

  desc "Stop Galaxy Toolshed"
  task :stop_galaxy_toolshed, :roles => :galaxy do
    run "cd $GALAXY_HOME && #{try_sudo} service toolshed stop", :env => {'RAILS_ENV' => stage}
  end

  desc "Configure Galaxy Toolshed"
  task :configure_galaxy_toolshed, :roles => :galaxy do
    toolshed_config = YAML.load_file('config/galaxy_toolshed.yml')[stage.to_s]
    run "sed -i 's+__TOOLSHED_PORT__+#{toolshed_port}+g' $GALAXY_HOME/tool_shed_wsgi.ini"
    run "sed -i 's+__USER__+#{toolshed_config["username"]}+g' $GALAXY_HOME/tool_shed_wsgi.ini"
    run "sed -i 's+__PASSWORD__+#{toolshed_config["password"]}+g' $GALAXY_HOME/tool_shed_wsgi.ini"
    run "sed -i 's+__HOST__+#{toolshed_config["host"]}+g' $GALAXY_HOME/tool_shed_wsgi.ini"
    run "sed -i 's+__DATABASE__+#{toolshed_config["database"]}+g' $GALAXY_HOME/tool_shed_wsgi.ini"
  end

  desc "Redeploy Galaxy toolshed"
  task :redeploy_galaxy_toolshed, :roles => :galaxy do
    set(:user) { "galaxy" }
    set :default_shell, '/bin/bash'
    stop_galaxy_toolshed
    configure_galaxy_toolshed
    start_galaxy_toolshed
  end

  desc "Restart Galaxy"
  task :restart_galaxy, :roles => :galaxy do
    set(:user) { "galaxy" }
    set :default_shell, '/bin/bash'
    run "cd $GALAXY_HOME && ./galaxy restart"
  end

end