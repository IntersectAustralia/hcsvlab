# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "~/hcsvlab-web/current/log/cron.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every :day, :at => '12:00am' do
  script "paradisec_poll.sh"
end

every 10.minutes do
  script "system_check.sh true"
end

case @environment
when 'production'
    every :day, :at => '1:30am' do
      script "galaxy_backup.sh"
    end
end
