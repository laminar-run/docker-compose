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

echo "Deleting old volumes..."
docker volume prune -f

echo "Removing files..."
rm -rf $PARENT_DIRECTORY/.env
rm -rf $PARENT_DIRECTORY/laminar_*.txt
rm -rf $PARENT_DIRECTORY/keycloak-realm.json