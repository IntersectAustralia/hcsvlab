# Your HTTP server, Apache/etc
role :web, 'alveo-staging2.intersect.org.au'
# This may be the same as your Web server
role :app, 'alveo-staging2.intersect.org.au'
# This is where Rails migrations will run
role :db,  'alveo-staging2.intersect.org.au', :primary => true

set :server_url, "http://alveo-staging2.intersect.org.au"