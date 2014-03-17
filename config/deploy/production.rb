# Your HTTP server, Apache/etc
role :web, 'hcsvlab-prod-webapp.intersect.org.au'
# This may be the same as your Web server
role :app, 'hcsvlab-prod-webapp.intersect.org.au'
# This is where Rails migrations will run
role :db,  'hcsvlab-prod-webapp.intersect.org.au', :primary => true

set :server_url, "http://app.hcsvlab.org.au/"
set :galaxy_port, "8081"
set :galaxy_ga_tracker_id, "UA-49039039-11"