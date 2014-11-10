#!/usr/bin/env ruby
# Make sure stdout and stderr write out without delay for using with daemon like scripts
STDOUT.sync = true; STDOUT.flush if STDOUT.respond_to? :flush
STDERR.sync = true; STDERR.flush if STDERR.respond_to? :flush

app_root = ENV['APP_ROOT'] || File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
application_file = File.join(app_root, 'config', 'environment.rb')

if File.exist?(application_file)
  load application_file
else
  raise "#{application_file} does not exist!"
end

Rails.logger = Logger.new(STDOUT)
ActiveMessaging.logger = Rails.logger
ActiveMessaging.logger.level = ActiveSupport::BufferedLogger.const_get(Rails.configuration.log_level.to_s.upcase)

# Load ActiveMessaging
ActiveMessaging::load_processors

# Start it up!
ActiveMessaging::start
