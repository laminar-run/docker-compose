#!/bin/bash
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIRECTORY="${SCRIPT_DIRECTORY%/*}"

# Check if .env exists:
if [ -f .env ]; then
  echo "It looks like you have already set up Laminar. If you want to reinstall, please remove the .env file and try again."
  echo "Would you like to start the server now? (Y/n)"
  read -r START_SERVER
  if [ "$START_SERVER" != "n" ]; then
    docker-compose up -d
  fi
  exit 0
fi

# Generate necessary keys and secrets
export SECRET=$(openssl rand -hex 20 | cut -c 1-32)
export NEXTAUTH_SECRET=$(openssl rand -base64 32)

# Ask for Docker Hub credentials
echo "What is your Laminar Docker Hub token or password?"
read -rs DOCKER_TOKEN

# Login to Docker Hub (assuming the username is always 'laminaronpremise')
echo "$DOCKER_TOKEN" | docker login -u laminaronpremise --password-stdin

# Confirm last command was successful:
if [ $? -ne 0 ]; then
  echo "Docker credentials are invalid. Please try again."
  exit 1
fi

# Set up environment variables
export SPRING_DATASOURCE_URL="jdbc:postgresql://db:5432/laminar"
export SPRING_DATASOURCE_USERNAME="laminar"
export SPRING_DATASOURCE_PASSWORD=$(openssl rand -hex 20 | cut -c 1-16)
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;AccountName=lamflowfiles;AccountKey=your_account_key;EndpointSuffix=core.windows.net"
export AZURE_STORAGE_SHARE_NAME="flowfiles"
export LOGGING_LEVEL_ROOT="WARN"
export LOGGING_LEVEL_WEB="INFO"
export LOGGING_LEVEL_RUN_LAMINAR="DEBUG"
export KEYCLOAK_REALM="laminar"
export KEYCLOAK_CLIENT_ID="laminar-client"
export KEYCLOAK_CLIENT_SECRET=$(openssl rand -hex 20)
export KEYCLOAK_ADMIN="admin"
export KEYCLOAK_ADMIN_PASSWORD=$(openssl rand -hex 20)
export NEXT_PUBLIC_POSTHOG_KEY=""
export NEXT_PUBLIC_POSTHOG_HOST="https://us.posthog.com"

# Create .env file
env | grep -E "SPRING_|AZURE_|LOGGING_|SECRET|KEYCLOAK_|NEXT_PUBLIC_|NEXTAUTH_" > .env

# Save important secrets to a separate file
echo "DATABASE_PASSWORD=${SPRING_DATASOURCE_PASSWORD}" > laminar_secrets.txt
echo "SECRET=${SECRET}" >> laminar_secrets.txt
echo "NEXTAUTH_SECRET=${NEXTAUTH_SECRET}" >> laminar_secrets.txt
echo "KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}" >> laminar_secrets.txt
echo "KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}" >> laminar_secrets.txt

echo "Environment setup complete. Important secrets have been saved to laminar_secrets.txt"
echo "Please keep this file secure and do not share it."

echo "Would you like to start the server now? (Y/n)"
read -r START_SERVER
if [ "$START_SERVER" != "n" ]; then
  docker-compose pull
  docker-compose up -d
fi

echo "Laminar setup complete!"