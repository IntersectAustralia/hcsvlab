#!/bin/bash
#
# Check: 
#
# 1. The amount of free disk space
# 2. Whether ActiveMQ is up and on the right ports
# 3. Fedora is up
# 4. Solr is up
# 5. The workers are running
# 6. The web app is running
#

RET_STATUS=0

ACTIVEMQ_URL="http://localhost:8161/"
ACTIVEMQ_USER="admin:admin"

WEB_PORT_NUMBER=3000
JAVA_PORT_NUMBER=8983

if [ ! -z "$RAILS_ENV" -a "$RAILS_ENV" != "development" ]
then
  WEB_PORT_NUMBER=80
  JAVA_PORT_NUMBER=8080
fi

WEB_URL="http://localhost:${WEB_PORT_NUMBER}/"
JAVA_URL="http://localhost:${JAVA_PORT_NUMBER}/"

echo ""
echo "Checking HCS vLab environment"

echo ""
echo "Rails env= $RAILS_ENV"
echo "Java Container url= $JAVA_URL"
echo "Web App url= $WEB_URL"

# Disk space

free_disk=`df -hP / | tail -1 | awk '{ print $4 }'`
echo "Free disk space= $free_disk"

# ActiveMQ

echo ""
echo "Checking ActiveMQ..."

let count=0
while [ $count -lt 15 -a "$aqm_status" == "" ]
do
  sleep 2
  aqm_status=`curl -I -u $ACTIVEMQ_USER $ACTIVEMQ_URL 2>/dev/null  | head -1 | awk '{print $2}' `
  let count=count+1
done

if [ "$aqm_status" == "200" ]
then
  echo "+ ActiveMQ is listening on port 8161 (status= $aqm_status)"
else
  echo "- WARN: It looks like ActiveMQ is not running (status= $aqm_status)"
  RET_STATUS=1
fi

mq_url="http://localhost:8161"

amq_61616=`netstat -an | grep 61616 | wc -l`

if [ $amq_61616 -eq 0 ]
then
  echo "- WARN: ActiveMQ is not listening on port 61616"
  RET_STATUS=1
else
  echo "+ ActiveMQ is listening on port 61616"
fi

amq_61613=`netstat -an | grep 61613 | wc -l`

if [ $amq_61613 -eq 0 ]
then
  echo "- WARN: ActiveMQ is not listening on port 61613"
  RET_STATUS=1
else
  echo "+ ActiveMQ is listening on port 61613"
fi

# Servlet Container - Jetty or Tomcat

echo ""
echo "Checking the Java Container..."

let count=0
while [ $count -lt 15 -a "$java_status" == "" ]
do
  sleep 2
  java_status=`curl -I -u $FEDORA_ADMIN ${JAVA_URL}fedora 2>/dev/null  | head -1 | awk '{print $2}' `
  let count=count+1
done

if [ "$java_status" == "200"  -o "$java_status" == "302" ]
then
  echo "+ The Java Container is listening on port $JAVA_PORT_NUMBER (status= $java_status)"
else
  echo "- WARN: It looks like the Java container is not running (status= $java_status)"
  RET_STATUS=1
fi

# Solr

solr_status=`curl -I ${JAVA_URL}solr/ 2>/dev/null  | head -1 | awk '{print $2}' `

if [ "$solr_status" == "200" -o "$solr_status" == "302" ]
then
  echo "+ It looks like Solr is available (status= $solr_status)"
else
  echo "- WARN: It looks like Solr is not running (status= $solr_status)"
  RET_STATUS=1
fi

# A13g workers

echo ""
echo "Checking A13g pollers..."

a13g_status=` ps auxw | grep [p]oller | wc -l `

if [ $a13g_status == 2 ]
then
  echo "+ It looks like the A13g pollers are running (processes= $a13g_status)"
else
  echo "- WARN: It looks like something is wrong with the A13g pollers (processes= $a13g_status)"
  RET_STATUS=1
fi

# Check the web app

echo ""
echo "Checking the web app..."

let count=0
while [ $count -lt 15 -a "$web_status" == "" ]
do
  sleep 2
  web_status=`curl -I  ${WEB_URL} 2>/dev/null  | head -1 | awk '{print $2}' `
  let count=count+1
done

if [ "$web_status" == "200"  -o "$web_status" == "302" ]
then
  echo "+ The Web App is listening on port $WEB_PORT_NUMBER (status= $web_status)"
else
  echo "- WARN: It looks like the Web App is not running (status= $web_status)"
  RET_STATUS=1
fi

# End

echo ""

exit $RET_STATUS
