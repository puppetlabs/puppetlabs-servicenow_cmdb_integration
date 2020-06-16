#!/bin/bash

function cleanup() {
  # bolt_upload_file isn't idempotent, so remove this directory
  # to ensure that later invocations of the setup_servicenow_instance
  # task _are_ idempotent
  rm -rf /tmp/servicenow
}
trap cleanup EXIT

rep=$(curl -s --unix-socket /var/run/docker.sock http://ping > /dev/null)
status=$?

if [ "$status" == "7" ]; then
    apt-get -qq update -y 1>&- 2>&-
    apt-get install -qq docker.io -y 1>&- 2>&-
fi

set -e

id=`docker ps -q -f name=mock_servicenow_instance -f status=running`

if [ ! -z "$id" ]
then
  echo "Killing the current mock ServiceNow container (id = ${id}) ..."
  docker rm --force ${id}
fi

docker build /tmp/servicenow -t mock_servicenow_instance
docker run -d --rm -p 1080:1080 --name mock_servicenow_instance mock_servicenow_instance 1>&- 2>&-

id=`docker ps -q -f name=mock_servicenow_instance -f status=running`

if [ -z "$id" ]
then
  echo 'Mock ServiceNow container start failed.'
  exit 1
fi

echo 'Mock ServiceNow container start succeeded.'
exit 0
