#!/bin/sh
# Set FEDORA_HOME and SOLR_HOME so the tomcat config can access them
JAVA_OPTS="$JAVA_OPTS -DFEDORA_HOME=$FEDORA_HOME -DSOLR_HOME=$SOLR_HOME"

# Bump up heap and permgen
JAVA_OPTS="$JAVA_OPTS -Xms512m -Xmx2g -XX:MaxPermSize=128m  -XX:+CMSClassUnloadingEnabled -XX:+CMSPermGenSweepingEnabled"

export JAVA_OPTS

echo "Using JAVA_OPTS: $JAVA_OPTS"

# Enable remote jmx connections for profiling
CATALINA_OPTS="$CATALINA_OPTS  -Dcom.sun.management.jmxremote.port=9000 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

export CATALINA_OPTS

echo "Using CATALINA_OPTS= $CATALINA_OPTS"
