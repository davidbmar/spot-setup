#!/usr/bin/env bash
# Purpose: Start the whisper-runpod container in detached mode and open
#          two interactive shells ("ssh"-style execs) into it sequentially.
#
# Usage:   chmod +x run_whisper_container.sh
#          ./run_whisper_container.sh
#
# Notes:
#   • The first shell opens; when you type `exit` you drop back to the script.
#   • The script then opens a second shell. Exit again to finish.
#   • Remove `--gpus all` if you don't have the NVIDIA Container Toolkit.
#   • Stop the container any time with:  docker stop whisper-test

set -euo pipefail

IMAGE="davidbmar/whisper-runpod:latest"
CONTAINER_NAME="whisper-test"
HOST_PORT=9000
CONTAINER_PORT=9000
DATA_DIR="$PWD/data"

# 1) (Optional) Authenticate if the image is private
# docker login   # <- uncomment if needed

printf "\n🔹 Pulling latest image: %s\n" "$IMAGE"
docker pull "$IMAGE"

echo "🔹 Removing any stale container with the same name (if exists)"
if docker ps -a --format '{{.Names}}' | grep -qw "$CONTAINER_NAME"; then
  docker rm -f "$CONTAINER_NAME"
fi

echo "🔹 Starting $CONTAINER_NAME in detached mode..."
docker run -d \
  --name "$CONTAINER_NAME" \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  -v "${DATA_DIR}":/app/data \
  -e AWS_PROFILE=dev \
  --gpus all \
  "$IMAGE"

echo "✅ Container is up. Opening first shell... (type 'exit' when done)"
docker exec -it "$CONTAINER_NAME" /bin/bash || docker exec -it "$CONTAINER_NAME" /bin/sh

echo "🔹 Opening second shell... (type 'exit' to finish)"
docker exec -it "$CONTAINER_NAME" /bin/bash || docker exec -it "$CONTAINER_NAME" /bin/sh

echo "🎉 All done. Container is still running in background."

