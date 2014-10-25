#!/bin/bash

for CORPUS in $@
do
  time bundle exec rake fedora:ingest corpus=$CORPUS
done
