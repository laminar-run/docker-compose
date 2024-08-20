#!/bin/bash

generate_realm_json() {
    local realm_name="$1"
    local client_id="$2"
    local client_secret="$3"
    cat << EOF > keycloak-realm.json
{
  "realm": "${realm_name}",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": true,
  "clients": [
    {
      "clientId": "${client_id}",
      "enabled": true,
      "clientAuthenticatorType": "client-secret",
      "secret": "${client_secret}",
      "redirectUris": ["http://*"],
      "webOrigins": ["http://*"],
      "protocol": "openid-connect",
      "publicClient": false,
      "bearerOnly": false,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "serviceAccountsEnabled": true
    }
  ]
}
EOF
}

SCRIPT_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PARENT_DIRECTORY="${SCRIPT_DIRECTORY%/*}"

echo "Setting up Laminar on-premise..."

# Check if .env exists:
if [ -f .env ]; then
  echo "It looks like you have already set up Laminar. If you want to reinstall, please remove the .env file and try again."
  echo "Would you like to start the server now? (Y/n)"
  read -r START_SERVER
  if [ "$START_SERVER" != "n" ]; then
    docker-compose pull
    docker-compose up -d
  fi
  exit 0
fi

# If token file exists, read the token from it
if [ -f $SCRIPT_DIRECTORY/.token ]; then
  DOCKER_TOKEN=$(cat $SCRIPT_DIRECTORY/.token)
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

# Generate necessary keys and secrets
export NEXTAUTH_SECRET=$(openssl rand -base64 32)

# Prompt for domain or use the default domain
echo "Enter the domain name or IP address for your Laminar installation (leave blank for localhost):"
read -r DOMAIN

if [ -z "$DOMAIN" ]; then
  DOMAIN="localhost"
fi

echo "Setting up Laminar for domain: $DOMAIN"

# Set up environment variables
export SPRING_DATASOURCE_URL="jdbc:postgresql://postgres:5432/laminar"
export SPRING_PROFILES_ACTIVE="prod"
export SPRING_DATASOURCE_USERNAME="laminar"
export SPRING_DATASOURCE_PASSWORD=$(openssl rand -hex 20 | cut -c 1-16)
export KEYCLOAK_REALM="laminar"
export KEYCLOAK_URI="http://keycloak:8080/realms/${KEYCLOAK_REALM}"
export KEYCLOAK_CLIENT_ID="laminar-client"
export KEYCLOAK_CLIENT_SECRET=$(openssl rand -hex 20)
export KEYCLOAK_ADMIN="admin"
export KEYCLOAK_ADMIN_PASSWORD=$(openssl rand -hex 20)
export LOGGING_LEVEL_ROOT="WARN"
export LOGGING_LEVEL_WEB="INFO"
export LOGGING_LEVEL_RUN_LAMINAR="DEBUG"
export API_PORT="8080"
export SPRING_TRANSACTION_DEFAULT_TIMEOUT="900"
export API_URL="http://localhost:8080"
export SERVER_TOMCAT_ACCEPT_COUNT="300"
export SERVER_TOMCAT_CONNECTION_TIMEOUT="20000"
export SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE="400"
export SPRING_DATASOURCE_HIKARI_MAX_LIFETIME="2000000"
export SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT="30000"
export NOTIFICATION_API_TOKEN=$(openssl rand -hex 20)
export TEMPORAL_SERVICE_ADDRESS="temporal:7233"
export NEXT_PUBLIC_POSTHOG_KEY=""
export NEXT_PUBLIC_POSTHOG_HOST="https://us.posthog.com"
export NEXTAUTH_URL="http://${DOMAIN}:3000"
export NEXT_PUBLIC_LAMINAR_API_URL="http://api:8080"
export ON_PREM=true

# Generate Keycloak realm JSON
generate_realm_json "$KEYCLOAK_REALM" "$KEYCLOAK_CLIENT_ID" "$KEYCLOAK_CLIENT_SECRET"

cat << EOF > laminar_secrets.txt
# Laminar On-Premise Secrets

# Database Password
DATABASE_PASSWORD=${SPRING_DATASOURCE_PASSWORD}

# Next.js Secret
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

# Keycloak Admin Password
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}

# Keycloak Client Secret
KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}

# Notification API Token
NOTIFICATION_API_TOKEN=${NOTIFICATION_API_TOKEN}

EOF

# Create .env file with a header and organized sections
cat << EOF > .env
# Laminar On-Premise Environment Configuration
# Generated on $(date)

# Database Configuration
SPRING_DATASOURCE_URL=${SPRING_DATASOURCE_URL}
SPRING_DATASOURCE_USERNAME=${SPRING_DATASOURCE_USERNAME}
SPRING_DATASOURCE_PASSWORD=${SPRING_DATASOURCE_PASSWORD}

# Spring and Server Configuration
SPRING_PROFILES_ACTIVE=${SPRING_PROFILES_ACTIVE}
API_PORT=${API_PORT}
API_URL=${API_URL}
SERVER_TOMCAT_ACCEPT_COUNT=${SERVER_TOMCAT_ACCEPT_COUNT}
SERVER_TOMCAT_CONNECTION_TIMEOUT=${SERVER_TOMCAT_CONNECTION_TIMEOUT}
SPRING_TRANSACTION_DEFAULT_TIMEOUT=${SPRING_TRANSACTION_DEFAULT_TIMEOUT}
SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE=${SPRING_DATASOURCE_HIKARI_MAXIMUM_POOL_SIZE}
SPRING_DATASOURCE_HIKARI_MAX_LIFETIME=${SPRING_DATASOURCE_HIKARI_MAX_LIFETIME}
SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT=${SPRING_DATASOURCE_HIKARI_CONNECTION_TIMEOUT}

# Logging Configuration
LOGGING_LEVEL_ROOT=${LOGGING_LEVEL_ROOT}
LOGGING_LEVEL_WEB=${LOGGING_LEVEL_WEB}
LOGGING_LEVEL_RUN_LAMINAR=${LOGGING_LEVEL_RUN_LAMINAR}

# Keycloak Configuration
KEYCLOAK_URI=${KEYCLOAK_URI}
KEYCLOAK_REALM=${KEYCLOAK_REALM}
KEYCLOAK_CLIENT_ID=${KEYCLOAK_CLIENT_ID}
KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}
KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN}
KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}

# Temporal Configuration
TEMPORAL_SERVICE_ADDRESS=${TEMPORAL_SERVICE_ADDRESS}

# Next.js Configuration
NEXTAUTH_URL=${NEXTAUTH_URL}
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}
NEXT_PUBLIC_LAMINAR_API_URL=${NEXT_PUBLIC_LAMINAR_API_URL}
NEXT_PUBLIC_POSTHOG_KEY=${NEXT_PUBLIC_POSTHOG_KEY}
NEXT_PUBLIC_POSTHOG_HOST=${NEXT_PUBLIC_POSTHOG_HOST}

# Other Configuration
ON_PREM=${ON_PREM}
NOTIFICATION_API_TOKEN=${NOTIFICATION_API_TOKEN}
EOF

# Output service access information to a file
cat << EOF > laminar_access_info.txt
Laminar On-Premise Service Access Information
=============================================
Generated on $(date)

Frontend Access
---------------
URL: ${NEXTAUTH_URL}

API Access
----------
URL: ${NEXT_PUBLIC_LAMINAR_API_URL}

Keycloak Access
---------------
URL: http://${DOMAIN}:8180
Admin Username: ${KEYCLOAK_ADMIN}
Admin Password: ${KEYCLOAK_ADMIN_PASSWORD}
Realm: ${KEYCLOAK_REALM}
Client ID: ${KEYCLOAK_CLIENT_ID}

Temporal Access
---------------
Service URL: ${TEMPORAL_SERVICE_ADDRESS}
UI URL: http://${DOMAIN}:8081

Database Access
---------------
Host: localhost
Port: 5432
Username: ${SPRING_DATASOURCE_USERNAME}
Password: ${SPRING_DATASOURCE_PASSWORD}
Database: laminar
Keycloak Database: keycloak

Important Notes
---------------
1. Please refer to laminar_secrets.txt for passwords and other sensitive information.
2. Keep both laminar_access_info.txt and laminar_secrets.txt secure and do not share them.
3. For detailed API usage and Keycloak configuration, please refer to the documentation.

EOF

echo "Laminar setup complete!"
echo "Environment configuration has been saved to .env"
echo "Service access information has been saved to laminar_access_info.txt"
echo "Important secrets have been saved to laminar_secrets.txt"
echo "Please keep these files secure and do not share them."

echo "You can now access the services as follows:"
echo "- Frontend: ${NEXTAUTH_URL}"
echo "- API: ${NEXT_PUBLIC_LAMINAR_API_URL}"
echo "- Keycloak: http://${DOMAIN}:8180"
echo "- Temporal UI: http://${DOMAIN}:8081"

echo "Would you like to start the server now? (Y/n)"
read -r START_SERVER
if [ "$START_SERVER" != "n" ]; then
  docker-compose pull
  docker-compose up -d
fi