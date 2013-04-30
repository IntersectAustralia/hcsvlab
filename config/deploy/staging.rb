# Your HTTP server, Apache/etc
role :web, 'ic2-hcsvlab-staging1-vm.intersect.org.au'
# This may be the same as your Web server
role :app, 'ic2-hcsvlab-staging1-vm.intersect.org.au'
# This is where Rails migrations will run
role :db,  'ic2-hcsvlab-staging1-vm.intersect.org.au', :primary => true

