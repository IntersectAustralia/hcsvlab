$: << File.expand_path('./lib', ENV['rvm_path'])
require 'bundler/capistrano'
require 'capistrano/ext/multistage'
require 'capistrano_colors'
require 'rvm/capistrano'
require 'deploy/create_deployment_record'
load 'deploy/assets'

set :whenever_environment, defer { stage }
set :whenever_command, "bundle exec whenever"

require "whenever/capistrano"

require Rails.root.join('db/seed_helper.rb')

set :shared_file_dir, "files"
set(:shared_file_path) { File.join(shared_path, shared_file_dir) }

set :keep_releases, 5
set :application, 'hcsvlab-web'
set :stages, %w(qa qa2 staging staging2 production)
set :default_stage, "qa"
set :rpms, "openssl openssl-devel curl-devel httpd-devel apr-devel apr-util-devel zlib zlib-devel libxml2 libxml2-devel libxslt libxslt-devel libffi mod_ssl mod_xsendfile"
set :shared_children, shared_children + %w(log_archive)
set :shell, '/bin/bash'
set :rvm_ruby_string, 'ruby-2.1.4@hcsvlab'
set :rvm_type, :user

set(:releases)  { capture("ls -x #{releases_path}", :except => { :no_release => true }).split.sort }

# Deploy using copy for now
set :scm, 'git'
# Uncomment to enable Jetty submodule
#set :git_enable_submodules, 1
set :repository, 'https://github.com/IntersectAustralia/hcsvlab.git'
set :deploy_via, :checkout
set :copy_exclude, [".git/*", "features/*", "spec/*", "test/*"]

# Fix an issue related to net-ssh, see https://github.com/net-ssh/net-ssh/issues/145
set :ssh_options, {
  config: false
}

#version tagging
set :branch do
  require 'colorize'
  default_tag = 'HEAD'

  availableLocalBranches = `git branch`.split (/\r?\n/)
  availableLocalBranches.map! { |s|  "(local) " + s.strip}

  availableRemoteBranches = `git branch -r`.split (/\r?\n/)
  availableRemoteBranches.map! { |s|  "(remote) " + s.split('/')[-1].strip}

  puts "Availible tags:".colorize(:yellow)
  puts `git tag`
  puts "Availible branches:".colorize(:yellow)
  availableLocalBranches.each {|s| puts s}
  availableRemoteBranches.each {|s| puts s.colorize(:red)}

  tag = Capistrano::CLI.ui.ask "Tag to deploy (make sure to push the branch/tag first) or HEAD?: [#{default_tag}] ".colorize(:yellow)
  tag = default_tag if tag.empty?
  tag = nil if tag.eql?("HEAD")

  tag
end

set(:user) { "#{defined?(user) ? user : 'devel'}" }
set(:group) { "#{defined?(group) ? group : user}" }
set(:user_home) { "/home/#{user}" }
set(:deploy_to) { "#{user_home}/#{application}" }

default_run_options[:pty] = true

# Extra capistrano tasks
Dir["config/recipes/*.rb"].each {|file| load file }

before 'deploy:setup' do
  server_setup.rpm_install
  server_setup.rvm.trust_rvmrc
  server_setup.gem_install
  server_setup.passenger
  server_setup.config.apache

end
after 'deploy:setup' do
  server_setup.filesystem.dir_perms
  server_setup.filesystem.mkdir_db_dumps
end

before 'deploy:update' do
  deploy.stop_services
end

after 'deploy:update' do
  server_setup.logging.rotation
  deploy.new_secret
  deploy.restart
  deploy.additional_symlinks
  deploy.write_tag
  deploy.start_services
  # We need to use our own cleanup task since there is an issue on Capistrano deploy:cleanup task
  #https://github.com/capistrano/capistrano/issues/474
  deploy.customcleanup
end

after 'deploy:safe' do
  populate_languages # Populate the languages table after deployment
end

namespace :deploy do

  desc "Write the tag that was deployed to a file on the server so we can display it on the app"
  task :write_tag, :except => {:no_release => true} do
    branchName = branch.nil? ? "HEAD" : branch

    availableTags = `git tag`.split( /\r?\n/ )
    haveToShowHash = !availableTags.any? { |s| s.include?(branchName) }

    current_deployed_version = branchName
    if (haveToShowHash)
      availableBranches = `git branch -a`.split( /\r?\n/ )
      fullBranchName = ("HEAD".eql?(branchName)) ? branchName : availableBranches.select { |s| s.include?(branchName) }.first.to_s.strip

      #since git marc the current branch with a *, we need to remove that character from the branch name
      fullBranchName.gsub!('*','').strip! if fullBranchName.include?('*')

      current_deployed_version += " (sha1:" + `git rev-parse --short #{fullBranchName}`.strip + ")"
    end

    put current_deployed_version, "#{current_path}/app/views/shared/_tag.html.haml"
  end

  # Passenger specifics: restart by touching the restart.txt file
  task :start, :roles => :app, :except => {:no_release => true} do
    restart
  end
  task :stop do
    ;
  end
  task :restart, :roles => :app, :except => {:no_release => true} do
    run "touch #{File.join(current_path, 'tmp', 'restart.txt')}"
  end

  # Remote bundle install
  task :rebundle, :roles => :app, :except => {:no_release => true} do
    run "cd #{current_path} && bundle install"
    restart
  end

  task :bundle_update, :roles => :app, :except => {:no_release => true} do
    run "cd #{current_path} && bundle update"
    restart
  end

  desc "Additional Symlinks to shared_path"
  task :additional_symlinks, :roles => :app, :except => {:no_release => true} do
    run "rm -rf #{release_path}/tmp/shared_config"
    run "mkdir -p #{shared_path}/env_config"
    run "ln -nfs #{shared_path}/env_config #{release_path}/tmp/env_config"

    run "rm -f #{release_path}/db_dumps"
    run "ln -s #{shared_path}/db_dumps #{release_path}/db_dumps"
  end

  # Load the schema
  desc "Load the schema into the database (WARNING: destructive!)"
  task :schema_load, :roles => :db do
    run("cd #{current_path} && bundle exec rake db:schema:load", :env => {'RAILS_ENV' => "#{stage}"})
  end

  # Run the sample data populator
  desc "Run the test data populator script to load test data into the db (WARNING: destructive!)"
  task :populate, :roles => :db do
    generate_populate_yml
    run("cd #{current_path} && bundle exec rake db:populate", :env => {'RAILS_ENV' => "#{stage}"})
  end

  # Seed the db
  desc "Run the seeds script to load seed data into the db (WARNING: destructive!)"
  task :seed, :roles => :db do
    run("cd #{current_path} && bundle exec rake db:seed", :env => {'RAILS_ENV' => "#{stage}"})
  end

  desc "Full redeployment, it runs deploy:update and deploy:refresh_db"
  task :full_redeploy, :except => {:no_release => true} do
    update
    refresh_db

    configure_activemq
    configure_solr
    configure_tomcat6

  end

  task :configure do
    configure_activemq
    configure_solr
    configure_tomcat6
  end

  # Helper task which re-creates the database
  task :refresh_db, :roles => :db do
    require 'colorize'

    # Prompt to refresh_db on unless we're in QA
    if stage.eql?(:qa)
      input = "yes"
    else
      puts "This step (deploy:refresh_db) will erase all data and start from scratch.\nYou probably don't want to do it. Are you sure?' [NO/yes]".colorize(:red)
      input = STDIN.gets.chomp
    end

    if input.match(/^yes/)
      schema_load
      seed
      populate
    else
      puts "Skipping database nuke"
    end
  end

  desc "Safe redeployment"
  task :safe, :except => {:no_release => true} do
    require 'colorize'
    update

    cat_migrations_output = capture("cd #{current_path} && bundle exec rake db:cat_pending_migrations 2>&1", :env => {'RAILS_ENV' => stage}).chomp
    puts cat_migrations_output

    if !cat_migrations_output[/^0 pending migration/]
      print "There are pending migrations. Are you sure you want to continue? [NO/yes] ".colorize(:red)
      abort "Exiting because you didn't type 'yes'" unless STDIN.gets.chomp == 'yes'
    end

    backup.db.dump
    backup.db.trim
    migrate
    restart
  end

  desc "Generates new Secret Token"
  task :new_secret, :roles => :app do
    run("cd #{current_path} && bundle exec rake app:generate_secret", :env => {'RAILS_ENV' => "#{stage}"})
  end

  desc "Start ActiveMQ, Jetty, the A13g workers"
  task :start_services, :roles => :app do
    start_a13g_pollers
  end

  desc "Stop ActiveMQ, Jetty, the A13g workers"
  task :stop_services, :roles => :app do
    stop_a13g_pollers
  end

  # We need to define our own cleanup task since there is an issue on Capistrano deploy:cleanup task
  #https://github.com/capistrano/capistrano/issues/474
  task :customcleanup, :except => {:no_release => true} do
      count = fetch(:keep_releases, 5).to_i
      run "ls -1dt #{releases_path}/* | tail -n +#{count + 1} | xargs rm -rf"
  end

  task :create_symlink, :except => { :no_release => true } do
    on_rollback do
      if previous_release
        run "rm -f #{current_path}; ln -s #{previous_release} #{current_path}; true"
      else
        logger.important "no previous release to rollback to, rollback of symlink skipped"
      end
    end

    run "rm -f #{current_path} && ln -s #{latest_release} #{current_path}"
  end


end

namespace :backup do
  namespace :db do
    desc "make a database backup"
    task :dump, :roles => :db do
      run "cd #{current_path} && bundle exec rake db:backup", :env => {'RAILS_ENV' => stage}
    end

    desc "trim database backups"
    task :trim, :roles => :db do
      run "cd #{current_path} && bundle exec rake db:trim_backups", :env => {'RAILS_ENV' => stage}
    end
  end
end

desc "Give sample users a custom password"
task :generate_populate_yml, :roles => :app do
  require "yaml"
  require 'colorize'

  puts "Set sample user password? (required on initial deploy) [NO/yes]".colorize(:red)
  input = STDIN.gets.chomp
  do_set_password if input.match(/^yes/)
end

desc "Helper method that actually sets the sample user password"
task :do_set_password, :roles => :app do
  set :custom_sample_password, proc { Capistrano::CLI.password_prompt("Sample User password: ") }
  buffer = Hash[:password => custom_sample_password]
  put YAML::dump(buffer), "#{shared_path}/env_config/sample_password.yml", :mode => 0664
end

after 'multistage:ensure' do
  set(:rails_env) { "#{defined?(rails_env) ? rails_env : stage.to_s}" }
  set :shared_files, %W(
    config/environments/#{stage}.rb
    config/deploy/#{stage}.rb
    config/aaf_rc.yml
    config/database.yml
    config/hcsvlab-web_config.yml
    config/linguistics.yml
    config/solr.yml
    config/newrelic.yml
    config/aspera.yml
    )
end
