# Your HTTP server, Apache/etc
role :web, 'hcsvlab-v1-webapp.intersect.org.au'
# This may be the same as your Web server
role :app, 'hcsvlab-v1-webapp.intersect.org.au'
# This is where Rails migrations will run
role :db,  'hcsvlab-v1-webapp.intersect.org.au', :primary => true