#!/bin/sh

# The following variables should be defined in .bashrc
#
# ROBOCHEF_PATH - path to robochef folder
# RAW_PATH - path to store raw files
# PROCESSED_PATH - path to store robochefed files
# ROBOCHEF_VENV - path to the virtualenv activate script for robochef


source $HOME/.bash_profile
source $ROBOCHEF_VENV

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
if [ -z "$RAILS_ENV" ]; then
    RAILS_ENV=development
fi

echo "Rails env= $RAILS_ENV"

if [ -d "$ROBOCHEF_PATH" ]
then
    cd $ROBOCHEF_PATH
    git pull
else
    mkdir -p $ROBOCHEF_PATH
    git clone https://github.com/IntersectAustralia/hcsvlab_robochef $ROBOCHEF_PATH
    cd $ROBOCHEF_PATH
fi

function setup_error {
    if [ $1 -ne 0 ]
    then
      echo "Error setting up Robochef."
      exit $1
    fi
}
if [ -f "bin/activate" ]
then
    source bin/activate
else
    sudo chown -R devel:devel /usr/local/
    which python2.7
    if [ $? -ne 0 ]
    then
        curl -OL http://python.org/ftp/python/2.7.5/Python-2.7.5.tgz
        tar xvf Python-2.7.5.tgz
        cd Python-2.7.5
        ./configure --prefix=/usr/local
        sudo make && sudo make altinstall
        sudo chown -R devel:devel /usr/local/lib/python2.7
        sudo chmod -r a+w /usr/local/lib/python2.7

        setup_error $?
        cd $ROBOCHEF_PATH
    fi

    cp $ROBOCHEF_PATH/config.ini.dist $ROBOCHEF_PATH/config.ini
    echo "DOCUMENT_BASE_URL = file:///data/production_collections/" >> $ROBOCHEF_PATH/config.ini
    echo "CORPUS_BASEDIR = ${RAW_PATH}/" >> $ROBOCHEF_PATH/config.ini
    echo "CORPUS_OUTPUTDIR = ${PROCESSED_PATH}/" >> $ROBOCHEF_PATH/config.ini

    curl https://bootstrap.pypa.io/ez_setup.py -o - | python2.7
    setup_error $?
    easy_install-2.7 virtualenv
    setup_error $?
    virtualenv-2.7 .
    setup_error $?
    source bin/activate
    setup_error $?
    pip install "pyparsing<=1.5.7" xlrd "rdflib<=3.4.0" httplib2 rdfextras
    setup_error $?
fi

LOGFILE=$DIR/../log/paradisec_ingest.log
echo "Logging to $LOGFILE"
echo "===== Begin $( date '+%Y-%m-%d %H.%M.%S' )" >> $LOGFILE
rm -r ${RAW_PATH}/paradisec
python hcsvlab_robochef/paradisec/harvest/harvester.py ${RAW_PATH}/paradisec >> $LOGFILE 2>&1
python hcsvlab_robochef/paradisec/harvest/collection_harvester.py ${RAW_PATH}/paradisec >> $LOGFILE 2>&1
python main.py paradisec >> $LOGFILE 2>&1
if [ $? -ne 0 ]
then
  echo "Error manifesting PARADISEC. Check cron.log or paradisec_ingest.log"
  exit 1
fi
cd $DIR/..
bundle exec rake fedora:paradisec_clear

declare corpora

for f in `find ${PROCESSED_PATH}/paradisec -type d| sort`
do
   if test -n "$(find ${f} -maxdepth 1 -name '*-metadata.rdf' -print -quit)"
   then
      echo "... queuing $f for ingest"
      corpora+=" $f"
   fi
done

./nohup_ingest_all_bg.sh ${corpora} >> $LOGFILE 2>&1
echo "===== End $( date '+%Y-%m-%d %H.%M.%S' )" >> $LOGFILE
