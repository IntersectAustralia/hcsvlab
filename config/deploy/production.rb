# Your HTTP server, Apache/etc
role :web, 'app.alveo.edu.au'
# This may be the same as your Web server
role :app, 'app.alveo.edu.au'
# This is where Rails migrations will run
role :db,  'app.alveo.edu.au', :primary => true
# Galaxy VM
role :galaxy, '130.56.249.65', :no_release => true

set :server_url, "https://app.alveo.edu.au/"
set :galaxy_url, "http://130.56.249.65"
set :galaxy_port, "8081"
set :galaxy_ga_tracker_id, "UA-49039039-11"
set :galaxy_smtp_server, "localhost:25"
