# Your HTTP server, Apache/etc
role :web, 'hcsvlab-changeme'
# This may be the same as your Web server
role :app, 'hcsvlab-changeme'
# This is where Rails migrations will run
role :db,  'hcsvlab-changeme', :primary => true

