# Your HTTP server, Apache/etc
role :web, 'app.alveo.edu.au'
# This may be the same as your Web server
role :app, 'app.alveo.edu.au'
# This is where Rails migrations will run
role :db,  'app.alveo.edu.au', :primary => true

set :server_url, "https://app.alveo.edu.au/"