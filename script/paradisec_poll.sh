#!/bin/sh

source $HOME/.bash_profile

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -z "$RAILS_ENV" ]; then
    RAILS_ENV=development
fi

robochef_path=/data/${RAILS_ENV}/paradisec_robochef
raw_path=/data/${RAILS_ENV}/raw
processed_path=/data/${RAILS_ENV}/processed

echo "Rails env= $RAILS_ENV"

if [ -d "$robochef_path" ]
then
    cd $robochef_path
    git pull
else
    mkdir -p $robochef_path
    git clone https://github.com/IntersectAustralia/hcsvlab_robochef $robochef_path
    cd $robochef_path
fi

if [ -f "bin/activate" ]
then
    source bin/activate
else
    cp $robochef_path/config.ini.dist $robochef_path/config.ini
    echo "DOCUMENT_BASE_URL = file:///data/production_collections/" >> $robochef_path/config.ini
    echo "CORPUS_BASEDIR = ${raw_path}/" >> $robochef_path/config.ini
    echo "CORPUS_OUTPUTDIR = ${processed_path}/" >> $robochef_path/config.ini
    curl https://bootstrap.pypa.io/ez_setup.py -o - | sudo python
    easy_install-2.7 virtualenv
    virtualenv .
    source bin/activate
    pip install "pyparsing<=1.5.7" xlrd "rdflib<=3.4.0" httplib2 rdfextras
fi

logfile=$DIR/../log/paradisec_ingest.log
echo "Logging to $logfile"
echo "===== Begin $( date '+%Y-%m-%d %H.%M.%S' )" >> $logfile
rm -r ${raw_path}/paradisec
bin/python2.7 hcsvlab_robochef/paradisec/harvest/harvester.py ${raw_path}/paradisec >> $logfile 2>&1
bin/python2.7 hcsvlab_robochef/paradisec/harvest/collection_harvester.py ${raw_path}/paradisec >> $logfile 2>&1
bin/python2.7 main.py paradisec >> $logfile 2>&1

cd $DIR/..
bundle exec rake fedora:paradisec_clear

declare corpora

for f in `find ${processed_path}/paradisec -type d| sort`
do
   if test -n "$(find ${f} -maxdepth 1 -name '*-metadata.rdf' -print -quit)"
   then
      echo "... queuing $f for ingest"
      corpora+=" $f"
   fi
done

./nohup_ingest_all_bg.sh ${corpora} >> $logfile 2>&1
echo "===== End $( date '+%Y-%m-%d %H.%M.%S' )" >> $logfile
