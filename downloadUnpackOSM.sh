#!/bin/bash

## NOTE: I wrote this before I realized that the heidelberg.osm is actually the default .osm packaged in the 
##       official openrouteservice docker image. The idea was to have an easy script to download, unpack,
##       convert, and move the .pbf into position to be packaged in a custom dockerfile.

file="heidelberg"

# Download Heidelberg.osm
curl -L https://github.com/GIScience/openrouteservice/raw/master/openrouteservice/src/main/files/heidelberg.osm.gz -o "${file}.osm.gz"

# Unzip
gzip -d "${file}.osm.gz"

osmium cat "${file}.osm" -o "${file}.pbf"
