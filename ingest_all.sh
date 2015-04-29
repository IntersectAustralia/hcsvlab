#!/bin/bash

DEFAULT_CORPUS_PATH=/data/processed
CORPUS_PATH=$1

if [ -z $CORPUS_PATH ]
then
  echo "Enter corpora base directory:"
  read -e -p "[$DEFAULT_CORPUS_PATH]: " CORPUS_PATH
else
  echo "Using $CORPUS_PATH from arguments"
fi

if [ -z $CORPUS_PATH ]
  then
    CORPUS_PATH=$DEFAULT_CORPUS_PATH
fi

declare corpora

for f in `find ${CORPUS_PATH} -type d| sort`
do
   if test -n "$(find ${f} -maxdepth 1 -name '*-metadata.rdf' -print -quit)"
   then
      echo "... queuing $f for ingest"
      corpora+=" $f"
   fi
done

if [ "${corpora}" != "" ]
  then
    nohup ./nohup_ingest_all_bg.sh ${corpora} &
  else
    echo "Error looking for collections in: $CORPUS_PATH"
fi