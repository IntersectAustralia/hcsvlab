# Your HTTP server, Apache/etc
role :web, 'alveo-qa2.intersect.org.au'
# This may be the same as your Web server
role :app, 'alveo-qa2.intersect.org.au'
# This is where Rails migrations will run
role :db,  'alveo-qa2.intersect.org.au', :primary => true

set :server_url, "http://alveo-qa2.intersect.org.au"