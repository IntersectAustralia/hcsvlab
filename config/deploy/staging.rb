# Your HTTP server, Apache/etc
role :web, 'ic2-hcsvlab-staging1-vm.intersect.org.au'
# This may be the same as your Web server
role :app, 'ic2-hcsvlab-staging1-vm.intersect.org.au'
# Galaxy VM
role :galaxy, '130.56.248.111'
# This is where Rails migrations will run
role :db,  'ic2-hcsvlab-staging1-vm.intersect.org.au', :primary => true

set :server_url, "http://ic2-hcsvlab-staging1-vm.intersect.org.au"
set :galaxy_url, "http://130.56.248.111"
set :galaxy_port, "8080"
set :toolshed_port, "9009"
set :galaxy_ga_tracker_id, "UA-49039039-10"
set :galaxy_smtp_server, "localhost:25"