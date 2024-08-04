#!/bin/bash

# Turn on bash's job control
set -m

# Function to create a database
create_database() {
    local db=$1
    echo "Creating or verifying database: $db"
    psql -v ON_ERROR_STOP=0 --username "$POSTGRES_USER" <<-EOSQL
    SELECT 'CREATE DATABASE $db'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$db')\gexec
    GRANT ALL PRIVILEGES ON DATABASE $db TO $POSTGRES_USER;
EOSQL
}

# Main execution
if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
    echo "Multiple database creation requested: $POSTGRES_MULTIPLE_DATABASES"
    for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
        create_database $db
    done
    echo "Database creation/verification complete"
fi