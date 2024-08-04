#!/bin/bash
SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIRECTORY="${SCRIPT_DIRECTORY%/*}"

echo "Setting up Laminar on-premise..."

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

# If token file exists, read the token from it
if [ -f $PARENT_DIRECTORY/.token ]; then
  DOCKER_TOKEN=$(cat $PARENT_DIRECTORY/.token)
fi

# If token is not set, prompt user for token
if [ -z "$DOCKER_TOKEN" ]; then
  echo "What is your Laminar on-premise Docker Hub token?"
  read -rs DOCKER_TOKEN
fi

echo "$DOCKER_TOKEN" | docker login -u laminaronpremise --password-stdin

# Confirm last command was successful:
if [ $? -ne 0 ]; then
  echo "Docker credentials are invalid. Please try again."
  exit 1
fi

mkdir -p certs

# Generate necessary keys and secrets
export SECRET=$(openssl rand -hex 20 | cut -c 1-32)
export NEXTAUTH_SECRET=$(openssl rand -base64 32)

# HTTPS is always enabled with Nginx
export USE_HTTPS=true

# Generate self-signed SSL certificate
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout certs/tls.key -out certs/tls.crt -subj "/CN=localhost"

# Create a PKCS12 keystore for the API
export SSL_KEYSTORE_PASSWORD=$(openssl rand -hex 16)
openssl pkcs12 -export -in certs/tls.crt -inkey certs/tls.key -out certs/keystore.p12 -name laminar -password pass:$SSL_KEYSTORE_PASSWORD

# Set up environment variables
export SPRING_DATASOURCE_URL="jdbc:postgresql://postgres:5432/laminar"
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
export SPRING_TRANSACTION_DEFAULT_TIMEOUT="900"
export API_URL="https://localhost/laminar-api"
export SERVER_TOMCAT_ACCEPT_COUNT="300"
export SERVER_TOMCAT_CONNECTION_TIMEOUT="20000"
export SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE="400"
export SPRING_DATASOURCE_HIKARI_MAX_LIFETIME="2000000"
export SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT="30000"
export NOTIFICATION_API_TOKEN=$(openssl rand -hex 20)
export TEMPORAL_SERVICE_ADDRESS="temporal:7233"
export NEXT_PUBLIC_POSTHOG_KEY=""
export NEXT_PUBLIC_POSTHOG_HOST="https://us.posthog.com"

export NEXTAUTH_URL="https://localhost"
export NEXT_PUBLIC_LAMINAR_API_URL="https://localhost/laminar-api"
export NEXT_PUBLIC_KEYCLOAK_URL="https://localhost/auth"

# Create .env file
# Create .env file
env | grep -E "SPRING_|SECRET|KEYCLOAK_|NEXT_|NEXTAUTH_|USE_HTTPS|LOGGING_|SSL_KEYSTORE_PASSWORD|API_PORT|API_URL|SERVER_TOMCAT_|NOTIFICATION_API_TOKEN|TEMPORAL_SERVICE_ADDRESS|POSTGRES_PASSWORD|LOGTAIL_SOURCE_TOKEN" > .env

# Save important secrets to a separate file
echo "DATABASE_PASSWORD=${SPRING_DATASOURCE_PASSWORD}" > laminar_secrets.txt
echo "SECRET=${SECRET}" >> laminar_secrets.txt
echo "NEXTAUTH_SECRET=${NEXTAUTH_SECRET}" >> laminar_secrets.txt
echo "KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}" >> laminar_secrets.txt
echo "KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}" >> laminar_secrets.txt
echo "NOTIFICATION_API_TOKEN=${NOTIFICATION_API_TOKEN}" >> laminar_secrets.txt
echo "SSL_KEYSTORE_PASSWORD=${SSL_KEYSTORE_PASSWORD}" >> laminar_secrets.txt

# Output service access information to a file
cat << EOF > laminar_access_info.txt
Laminar Service Access Information:

Frontend: ${NEXTAUTH_URL}
API: ${NEXT_PUBLIC_LAMINAR_API_URL}
Keycloak: ${NEXT_PUBLIC_KEYCLOAK_URL}
Temporal: https://localhost/temporal
Temporal UI: https://localhost/temporal

Database:
  Host: localhost
  Port: 5432
  Username: laminar
  Database: laminar

Please refer to laminar_secrets.txt for passwords and other sensitive information.
EOF

echo "Laminar setup complete!"
echo "Service access information has been saved to laminar_access_info.txt"
echo "Important secrets have been saved to laminar_secrets.txt"
echo "Please keep these files secure and do not share them."

echo "HTTPS is enabled. You can access the application at https://localhost"
echo "API is available at ${NEXT_PUBLIC_LAMINAR_API_URL}"
echo "Keycloak is available at ${NEXT_PUBLIC_KEYCLOAK_URL}"
echo "Temporal UI is available at https://localhost/temporal"
echo "Please refer to the documentation for further instructions on using the API and configuring Keycloak."

echo "Would you like to start the server now? (Y/n)"
read -r START_SERVER
if [ "$START_SERVER" != "n" ]; then
  docker-compose pull
  docker-compose up -d
fi