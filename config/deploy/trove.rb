# Your HTTP server, Apache/etc
role :web, 'alveo.intersect.org.au'
# This may be the same as your Web server
role :app, 'alveo.intersect.org.au'
# This is where Rails migrations will run
role :db,  'alveo.intersect.org.au', :primary => true

set :server_url, "https://alveo.intersect.org.au/"