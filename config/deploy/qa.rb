# Your HTTP server, Apache/etc
role :web, 'ic2-hcsvlab-test4-vm.intersect.org.au'
# This may be the same as your Web server
role :app, 'ic2-hcsvlab-test4-vm.intersect.org.au'
# Galaxy VM
role :galaxy, '115.146.86.158'
# This is where Rails migrations will run
role :db,  'ic2-hcsvlab-test4-vm.intersect.org.au', :primary => true

set :server_url, "http://ic2-hcsvlab-test4-vm.intersect.org.au"
set :galaxy_url, "http://115.146.86.158"
set :galaxy_port, "8080"
set :toolshed_port, "9009"