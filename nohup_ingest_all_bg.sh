#!/bin/bash

for CORPUS in $@
do
  time rake fedora:ingest corpus=$CORPUS
done
