#!/bin/bash

rep=$(curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null)
status=$?

if [ "$status" == "7" ]; then
    apt-get -qq update -y 1>&- 2>&-
    apt-get install -qq docker.io -y 1>&- 2>&-
fi

id=`docker ps -q -f name=mockserver -f status=running`

if [ -z "$id" ]
then
  docker run -d --rm -p 1080:1080 --name mockserver mockserver/mockserver 1>&- 2>&-
fi

id=`docker ps -q -f name=mockserver -f status=running`

if [ -z "$id" ]
then
  echo 'container start failed.'
  exit 1
fi

exit 0
