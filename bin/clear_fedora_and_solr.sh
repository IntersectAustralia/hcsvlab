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

if [ -z "$FEDORA_HOME" ]
then
    echo "Please set FEDORA_HOME"
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
rm -rf $SOLR_HOME/hcsvlab/solr/hcsvlab-AF-core/data/*

# Clear Fedora

echo ""
echo "Deleting Fedora data files..."

rm -rf $FEDORA_HOME/data/objectStore/*
rm -rf $FEDORA_HOME/data/datastreamStore/*
rm -rf $FEDORA_HOME/derby/*

# Rebuild Fedora SQL db

echo ""
echo "Running the Fedora rebuild script to rebuild the SQL Database"
echo "Select 2 - Rebuild SQL database. and then 1 - Yes"
echo ""

$FEDORA_HOME/server/bin/fedora-rebuild.sh


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