# Your HTTP server, Apache/etc
role :web, 'hcsvlab-prod-webapp.intersect.org.au/'
# This may be the same as your Web server
role :app, 'hcsvlab-prod-webapp.intersect.org.au/'
# This is where Rails migrations will run
role :db,  'hcsvlab-prod-webapp.intersect.org.au/', :primary => true
