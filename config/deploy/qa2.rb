# Your HTTP server, Apache/etc
role :web, 'alveo-qa2.intersect.org.au'
# This may be the same as your Web server
role :app, 'alveo-qa2.intersect.org.au'
# Galaxy VM
role :galaxy, '115.146.92.203'
# This is where Rails migrations will run
role :db,  'alveo-qa2.intersect.org.au', :primary => true

set :server_url, "http://alveo-qa2.intersect.org.au"
set :galaxy_url, "http://115.146.92.203"
set :galaxy_port, "8080"
set :toolshed_port, "9009"
set :galaxy_ga_tracker_id, "UA-49039039-8"
set :galaxy_smtp_server, "localhost:25"