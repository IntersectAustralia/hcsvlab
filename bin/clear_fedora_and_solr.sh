#!/bin/bash

#
# Clear out Fedora & Solr by deleting the data on disk
# and then running the Fedora rebuild script to rebuild
# the SQL database.
#

if [ -z "$CATALINA_HOME" ]
then
    echo "Please set CATALINA_HOME"
    exit 1
fi

if [ -z "$SOLR_HOME" ]
then
    echo "Please set SOLR_HOME"
    exit 1
fi 

# Stop Apache Tomcat

echo ""
echo "Stopping apache tomcat..."
$CATALINA_HOME/bin/shutdown.sh


# Clear solr

echo ""
echo "Deleting Solr data files..."

rm -rf $SOLR_HOME/hcsvlab/solr/hcsvlab-core/data/*

# Start Apache Tomcat

echo ""
echo "Starting apache tomcat..."
$CATALINA_HOME/bin/startup.sh

sleep 10

echo ""
echo "Deleting Sesame triples"
echo ""
rake sesame:clear

exit 0