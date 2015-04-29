#!/bin/sh

source $HOME/.bash_profile

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -z "$RAILS_ENV" ]; then
    RAILS_ENV=development
fi

echo "Rails env= $RAILS_ENV"

if [ -d "/data/paradisec_robochef" ]
then
    cd /data/paradisec_robochef
    git pull https://github.com/IntersectAustralia/hcsvlab_robochef
else
    git clone https://github.com/IntersectAustralia/hcsvlab_robochef /data/paradisec_robochef
    cd /data/paradisec_robochef
fi

if [ -f "bin/activate" ]
then
    source bin/activate
else
    cp /data/paradisec_robochef/config.ini.dist /data/paradisec_robochef/config.ini
    echo "DOCUMENT_BASE_URL = file:///data/production_collections/" >> /data/paradisec_robochef/config.ini
    echo "CORPUS_BASEDIR = /data/${RAILS_ENV}_raw/" >> /data/paradisec_robochef/config.ini
    echo "CORPUS_OUTPUTDIR = /data/${RAILS_ENV}_processed/" >> /data/paradisec_robochef/config.ini
    curl https://bootstrap.pypa.io/ez_setup.py -o - | python
    easy_install-2.7 virtualenv
    virtualenv .
    source bin/activate
    pip install "pyparsing<=1.5.7" xlrd "rdflib<=3.4.0" httplib2 rdfextras
fi

logfile=$DIR/../log/$( date +%Y%m%d_%H.%M.%S )_paradisec_ingest.log
echo "Logging to $logfile"

rm -r /data/${RAILS_ENV}_raw/paradisec
bin/python2.7 hcsvlab_robochef/paradisec/harvest/harvester.py /data/${RAILS_ENV}_raw/paradisec >> $logfile 2>&1
bin/python2.7 hcsvlab_robochef/paradisec/harvest/collection_harvester.py /data/${RAILS_ENV}_raw/paradisec >> $logfile 2>&1
bin/python2.7 main.py paradisec >> $logfile 2>&1

cd $DIR/..
bundle exec rake fedora:paradisec_clear

declare corpora

for f in `find /data/${RAILS_ENV}_processed/paradisec -type d| sort`
do
   if test -n "$(find ${f} -maxdepth 1 -name '*-metadata.rdf' -print -quit)"
   then
      echo "... queuing $f for ingest"
      corpora+=" $f"
   fi
done

./nohup_ingest_all_bg.sh ${corpora} >> $logfile 2>&1
