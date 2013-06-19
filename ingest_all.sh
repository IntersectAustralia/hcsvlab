#!/bin/bash

DEFAULT_CORPUS_PATH=/data/processed

echo "Enter corpora base directory:"
read -e -p "[$DEFAULT_CORPUS_PATH]: " CORPUS_PATH

if [ -z $CORPUS_PATH ]
  then
    CORPUS_PATH=$DEFAULT_CORPUS_PATH
fi

CORPUS_PATHS=$(find "$CORPUS_PATH" -maxdepth 1 -type d)
if [ "$CORPUS_PATHS" ]
  then
    nohup ./nohup_ingest_all_bg.sh $CORPUS_PATHS &
  else
    echo "Error looking for subddirectories in: $CORPUS_PATH" 
fi