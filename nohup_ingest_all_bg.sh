#!/bin/bash

for CORPUS in $@
do
  rake fedora:ingest corpus=$CORPUS
done
