
ssh galaxy@galaxy.alveo.edu.au 'tar -zcf /mnt/galaxy/backups/$(date +%Y%m%d)_galaxy.tar /mnt/galaxy/galaxy-app/'
ssh galaxy@galaxy.alveo.edu.au 'pg_dump -U postgres toolshed  > /mnt/galaxy/backups/$(date +%Y%m%d)_toolshed.sql'
rsync --remove-source-files -azh galaxy@galaxy.alveo.edu.au:/mnt/galaxy/backups/ /data/galaxy_backups
find /data/galaxy_backups/ -mtime +30 -exec rm {} \;

# Ensure production VM has private key set up for galaxy user in galaxy server.
