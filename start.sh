#!/bin/bash

generate_realm_json() {
    local realm_name="$1"
    local client_id="$2"
    local client_secret="$3"
    local frontend_url="$4"

    cat << EOF > keycloak-realm.json
{
  "realm": "${realm_name}",
  "enabled": true,
  "sslRequired": "external",
  "registrationAllowed": true,
  "registrationEmailAsUsername": true,
  "verifyEmail": false,
  "loginWithEmailAllowed": true,
  "duplicateEmailsAllowed": false,
  "resetPasswordAllowed": true,
  "editUsernameAllowed": false,
  "clients": [
    {
      "clientId": "${client_id}",
      "enabled": true,
      "clientAuthenticatorType": "client-secret",
      "secret": "${client_secret}",
      "redirectUris": [
        "${frontend_url}/*",
        "http://localhost/*"
      ],
      "webOrigins": [
        "${frontend_url}",
        "http://localhost"
      ],
      "protocol": "openid-connect",
      "publicClient": false,
      "authorizationServicesEnabled": true,
      "serviceAccountsEnabled": true,
      "standardFlowEnabled": true,
      "implicitFlowEnabled": false,
      "directAccessGrantsEnabled": true,
      "frontchannelLogout": true,
      "attributes": {
        "pkce.code.challenge.method": "S256"
      }
    }
  ],
  "roles": {
    "realm": [
      {
        "name": "user",
        "description": "User role"
      },
      {
        "name": "admin",
        "description": "Admin role"
      }
    ]
  },
  "defaultRoles": ["user"],
  "scopeMappings": [
    {
      "client": "${client_id}",
      "roles": ["user"]
    }
  ],
  "clientScopes": [
    {
      "name": "profile",
      "protocol": "openid-connect",
      "attributes": {
        "include.in.token.scope": "true",
        "display.on.consent.screen": "true"
      },
      "protocolMappers": [
        {
          "name": "username",
          "protocol": "openid-connect",
          "protocolMapper": "oidc-usermodel-property-mapper",
          "consentRequired": false,
          "config": {
            "userinfo.token.claim": "true",
            "user.attribute": "username",
            "id.token.claim": "true",
            "access.token.claim": "true",
            "claim.name": "preferred_username",
            "jsonType.label": "String"
          }
        }
      ]
    }
  ],
  "defaultDefaultClientScopes": ["profile", "email"]
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
export SECRET=$(openssl rand -hex 20 | cut -c 1-32)
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
export NEXT_PUBLIC_LAMINAR_API_URL="http://${DOMAIN}:8080"
export ON_PREM=true

# Generate Keycloak realm JSON
generate_realm_json "$KEYCLOAK_REALM" "$KEYCLOAK_CLIENT_ID" "$KEYCLOAK_CLIENT_SECRET" "$NEXTAUTH_URL"

# Create .env file
env | grep -E "SPRING_|SECRET|KEYCLOAK_|NEXT_|NEXTAUTH_|USE_HTTPS|LOGGING_|SSL_KEYSTORE_PASSWORD|API_PORT|API_URL|SERVER_TOMCAT_|NOTIFICATION_API_TOKEN|TEMPORAL_SERVICE_ADDRESS|POSTGRES_PASSWORD|LOGTAIL_SOURCE_TOKEN|ON_PREM" > .env

# Save important secrets to a separate file
echo "DATABASE_PASSWORD=${SPRING_DATASOURCE_PASSWORD}" > laminar_secrets.txt
echo "SECRET=${SECRET}" >> laminar_secrets.txt
echo "NEXTAUTH_SECRET=${NEXTAUTH_SECRET}" >> laminar_secrets.txt
echo "KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}" >> laminar_secrets.txt
echo "KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}" >> laminar_secrets.txt
echo "NOTIFICATION_API_TOKEN=${NOTIFICATION_API_TOKEN}" >> laminar_secrets.txt

# Output service access information to a file
cat << EOF > laminar_access_info.txt
Laminar Service Access Information:

Frontend: ${NEXTAUTH_URL}
API: ${NEXT_PUBLIC_LAMINAR_API_URL}
Keycloak: ${NEXT_PUBLIC_KEYCLOAK_URL}
  - Username: ${KEYCLOAK_ADMIN}
  - Password: ${KEYCLOAK_ADMIN_PASSWORD}
Temporal: http://${DOMAIN}:7233
Temporal UI: http://${DOMAIN}:8081

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

echo "You can access the application at ${NEXTAUTH_URL}"
echo "API will be available at ${NEXT_PUBLIC_LAMINAR_API_URL}"
echo "Keycloak will be available at ${NEXT_PUBLIC_KEYCLOAK_URL}"
echo "Temporal UI will be available at http://${DOMAIN}:8081"
echo "Please refer to the documentation for further instructions on using the API and configuring Keycloak."

echo "Would you like to start the server now? (Y/n)"
read -r START_SERVER
if [ "$START_SERVER" != "n" ]; then
  docker-compose pull
  docker-compose up -d
fi