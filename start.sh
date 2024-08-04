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
  
  # Create a PKCS12 keystore for the API
  export SSL_KEYSTORE_PASSWORD=$(openssl rand -hex 16)
  openssl pkcs12 -export -in certs/tls.crt -inkey certs/tls.key -out certs/keystore.p12 -name laminar -password pass:$SSL_KEYSTORE_PASSWORD
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
export LOGGING_LEVEL_ROOT="WARN"
export LOGGING_LEVEL_WEB="INFO"
export LOGGING_LEVEL_RUN_LAMINAR="DEBUG"
export KEYCLOAK_PORT="8180"
export API_PORT="8080"

if [[ $USE_HTTPS == true ]]; then
  export NEXTAUTH_URL="https://localhost"
  export NEXT_PUBLIC_LAMINAR_API_URL="https://localhost:${API_PORT}"
  export NEXT_PUBLIC_KEYCLOAK_URL="https://localhost:${KEYCLOAK_PORT}"
else
  export NEXTAUTH_URL="http://localhost"
  export NEXT_PUBLIC_LAMINAR_API_URL="http://localhost:${API_PORT}"
  export NEXT_PUBLIC_KEYCLOAK_URL="http://localhost:${KEYCLOAK_PORT}"
fi

# Create .env file
env | grep -E "SPRING_|SECRET|KEYCLOAK_|NEXT_|NEXTAUTH_|USE_HTTPS|LOGGING_|SSL_KEYSTORE_PASSWORD|API_PORT" > .env

# Save important secrets to a separate file
echo "DATABASE_PASSWORD=${SPRING_DATASOURCE_PASSWORD}" > laminar_secrets.txt
echo "SECRET=${SECRET}" >> laminar_secrets.txt
echo "NEXTAUTH_SECRET=${NEXTAUTH_SECRET}" >> laminar_secrets.txt
echo "KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}" >> laminar_secrets.txt
echo "KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}" >> laminar_secrets.txt
if [[ $USE_HTTPS == true ]]; then
  echo "SSL_KEYSTORE_PASSWORD=${SSL_KEYSTORE_PASSWORD}" >> laminar_secrets.txt
fi

echo "Environment setup complete. Important secrets have been saved to laminar_secrets.txt"
echo "Please keep this file secure and do not share it."

echo "Would you like to start the server now? (Y/n)"
read -r START_SERVER
if [ "$START_SERVER" != "n" ]; then
  docker-compose pull
  docker-compose up -d
fi

echo "Laminar setup complete!"

if [[ $USE_HTTPS == true ]]; then
  echo "HTTPS is enabled. You can access the application at https://localhost"
  echo "API is available at https://localhost:${API_PORT}"
else
  echo "HTTP is enabled. You can access the application at http://localhost"
  echo "API is available at http://localhost:${API_PORT}"
fi

echo "Keycloak is available at ${NEXT_PUBLIC_KEYCLOAK_URL}"
echo "Please refer to the documentation for further instructions on using the API and configuring Keycloak."