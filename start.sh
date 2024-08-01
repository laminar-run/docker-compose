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

# Ask if HTTPS should be enabled
echo "Do you want to enable HTTPS? (y/N)"
read -r ENABLE_HTTPS
ENABLE_HTTPS=${ENABLE_HTTPS:-n}

if [[ $ENABLE_HTTPS =~ ^[Yy]$ ]]; then
  # Generate self-signed SSL certificate
  mkdir -p certs
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout certs/tls.key -out certs/tls.crt -subj "/CN=localhost"
  export USE_HTTPS=true
else
  export USE_HTTPS=false
fi

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
export KEYCLOAK_REALM="laminar"
export KEYCLOAK_CLIENT_ID="laminar-client"
export KEYCLOAK_CLIENT_SECRET=$(openssl rand -hex 20)
export KEYCLOAK_ADMIN="admin"
export KEYCLOAK_ADMIN_PASSWORD=$(openssl rand -hex 20)

if [[ $USE_HTTPS == true ]]; then
  export NEXTAUTH_URL="https://localhost"
  export NEXT_PUBLIC_LAMINAR_API_URL="https://api:8080"
  export NEXT_PUBLIC_KEYCLOAK_URL="https://keycloak:8180"
else
  export NEXTAUTH_URL="http://localhost"
  export NEXT_PUBLIC_LAMINAR_API_URL="http://api:8080"
  export NEXT_PUBLIC_KEYCLOAK_URL="http://keycloak:8080"
fi

# Create .env file
env | grep -E "SPRING_|AZURE_|SECRET|KEYCLOAK_|NEXT_|NEXTAUTH_|USE_HTTPS" > .env

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