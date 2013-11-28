# Your HTTP server, Apache/etc
role :web, 'ic2-hcsvlab-qa2-vm.intersect.org.au'
# This may be the same as your Web server
role :app, 'ic2-hcsvlab-qa2-vm.intersect.org.au'
# This is where Rails migrations will run
role :db,  'ic2-hcsvlab-qa2-vm.intersect.org.au', :primary => true

set :server_url, "http://ic2-hcsvlab-qa2-vm.intersect.org.au"
set :galaxy_port, "8081"
set :toolshed_port, "9009"