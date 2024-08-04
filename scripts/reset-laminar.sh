#!/bin/bash
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIRECTORY="${SCRIPT_DIRECTORY%/*}"
source $PARENT_DIRECTORY/.env
cd $PARENT_DIRECTORY

echo "Stopping and removing containers..."
docker-compose stop
docker-compose rm -f

echo "Pruning old images..."
docker image prune -a -f