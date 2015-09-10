'''
This is a script to scan completed or expired aspera transfers and remove the temp directories created for them
Make sure to replace the DB_PASSWORD below
Place this in the home folder for the devel user on the DTN, then add as a cron job:
  sudo crontab -e
  > 30 2 * * * python /home/devel/clear_aspera_tmp.py
'''
import os.path
import mysql.connector
import shutil

def clear_temp_dir():
  # Connect to database
  cnx = mysql.connector.connect(user='logger',
                                password='DB_PASSWORD',
                                host='127.0.0.1',
                                port='3306',
                                database='aspera_console')

  cursor = cnx.cursor()

  # Get complete or expired sessions
  query = "SELECT fasp_files.file_fullpath FROM fasp_files INNER JOIN fasp_sessions ON fasp_files.session_id=fasp_sessions.session_id WHERE (fasp_sessions.status='completed' OR fasp_sessions.created_at < now() - interval 28 day) AND fasp_files.file_fullpath LIKE '%/production_collections/tmp/%/log.json'"

  cursor.execute(query)

  # Delete temp directory for each result if it exists
  for (row) in cursor:
    old_dir = os.path.dirname(row[0])
    if (os.path.exists(old_dir)):
      shutil.rmtree(old_dir)

  cnx.close()


if __name__ == '__main__':
  clear_temp_dir()