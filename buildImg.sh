#!/bin/bash

if [ "$#" -ne 1 ]; then
   echo "Invalid Usage"
   echo "Usage buildImg.sh <version>"
   echo "   Example buildImg.sh 0.1"
   exit 1
fi

docker build -t afwapiproxy:$1 .
docker save afwapiproxy:$1 -o afwapiproxy.tar

