# Your HTTP server, Apache/etc
role :web, 'alveo-qa.intersect.org.au'
# This may be the same as your Web server
role :app, 'alveo-qa.intersect.org.au'
# This is where Rails migrations will run
role :db,  'alveo-qa.intersect.org.au', :primary => true
# Galaxy VM
role :galaxy, '115.146.92.203', :no_release => true

set :server_url, "http://alveo-qa.intersect.org.au"
set :galaxy_url, "http://115.146.92.203"
set :galaxy_port, "8080"
set :toolshed_port, "9009"
set :galaxy_ga_tracker_id, "UA-49039039-7"
set :galaxy_smtp_server, "localhost:25"