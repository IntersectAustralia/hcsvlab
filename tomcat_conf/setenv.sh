# Set FEDORA_HOME and SOLR_HOME so the tomcat config can access them
JAVA_OPTS="$JAVA_OPTS -DFEDORA_HOME=$FEDORA_HOME -DSOLR_HOME=$SOLR_HOME"

# Bump up heap and permgen
JAVA_OPTS="$JAVA_OPTS -Xms256m -Xmx512m -XX:MaxPermSize=128m  -XX:+CMSClassUnloadingEnabled -XX:+CMSPermGenSweepingEnabled"

# Enable remote jmx connections for profiling
#JAVA_OPTS="$JAVA_OPTS  -Dcom.sun.management.jmxremote.port=9000 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

export JAVA_HOME

echo "Using JAVA_OPTS: $JAVA_OPTS"
