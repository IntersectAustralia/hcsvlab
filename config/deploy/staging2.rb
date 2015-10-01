# Your HTTP server, Apache/etc
role :web, 'alveo-staging2.intersect.org.au'
# This may be the same as your Web server
role :app, 'alveo-staging2.intersect.org.au'
# This is where Rails migrations will run
role :db,  'alveo-qa-pg.intersect.org.au', :primary => true
# Galaxy VM
role :galaxy, '130.220.209.74', :no_release => true

set :server_url, "http://alveo-staging2.intersect.org.au"
set :galaxy_url, "http://130.220.209.74"
set :galaxy_port, "8080"
set :toolshed_port, "9009"
set :galaxy_ga_tracker_id, "UA-49039039-9"
set :galaxy_smtp_server, "localhost:25"