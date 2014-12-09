#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

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
    echo "CORPUS_BASEDIR = /data/production_collections/raw_data_collections/" >> /data/paradisec_robochef/config.ini
    echo "CORPUS_OUTPUTDIR = /data/production_collections/20141119/" >> /data/paradisec_robochef/config.ini
    curl https://bootstrap.pypa.io/ez_setup.py -o - | sudo python
    easy_install-2.7 virtualenv
    virtualenv .
    source bin/activate
    pip install "pyparsing<=1.5.7" xlrd "rdflib<=3.4.0" httplib2 rdfextras
fi

bin/python2.7 hcsvlab_robochef/paradisec/harvest/harvester.py /data/production_collections/raw_data_collections/paradisec >> paradisec_ingest.log
bin/python2.7 hcsvlab_robochef/paradisec/harvest/collection_harvester.py /data/production_collections/raw_data_collections/paradisec >> paradisec_ingest.log
bin/python2.7 main.py paradisec >> paradisec_ingest.log

cd $DIR/..
bundle exec rake fedora:paradisec_clear
./ingest_all.sh /data/production_collections/20141119/paradisec
