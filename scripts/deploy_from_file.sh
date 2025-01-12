#!/bin/bash

ENV_FILE="../.env"

if [ ! -f "$ENV_FILE" ]; then
    echo "Plik $ENV_FILE nie istnieje. Upewnij się, że plik znajduje się katalog wyżej."
    exit 1
fi

export $(grep -v '^#' "$ENV_FILE" | xargs)

CONTAINER_NAME="whatsappbroski-app"

if docker ps --filter "name=${CONTAINER_NAME}" --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Kontener '${CONTAINER_NAME}' działa. Zatrzymuję..."
    docker stop "${CONTAINER_NAME}"
    echo "Kontener '${CONTAINER_NAME}' został zatrzymany."
else
    echo "Kontener '${CONTAINER_NAME}' nie działa."
fi

set -ex

docker network create whatsapp-network

echo "$DOCKERHUB_TOKEN" | docker login -u "$DOCKERHUB_USERNAME" --password-stdin docker.io
docker pull msj102/whatsappbroski:latest
docker run -d --network whatsapp-network \
  -e WHATSAPP_API_URL="${WHATSAPP_API_URL}" \
  -e WHATSAPP_API_TOKEN="${WHATSAPP_API_TOKEN}" \
  -e WHATSAPP_API_WEBHOOK_TOKEN="${WHATSAPP_API_WEBHOOK_TOKEN}" \
  -e OPENAI_API_MODEL="${OPENAI_API_MODEL}" \
  -e OPENAI_API_KEY="${OPENAI_API_KEY}" \
  -p "8080:8080" --name $CONTAINER_NAME --rm msj102/whatsappbroski

while ! curl -s http://localhost:8080 > /dev/null; do
  echo "Czekam na uruchomienie aplikacji Spring Boot..."
  sleep 1
done
echo "Aplikacja działa!"

docker run --network whatsapp-network --name cloudflared cloudflare/cloudflared:latest tunnel --no-autoupdate run --token "${CLOUDFLARE_TOKEN}"