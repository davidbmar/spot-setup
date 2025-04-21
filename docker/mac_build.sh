#!/bin/bash
# Enable BuildKit for cross‑platform builds (macOS → linux/amd64)
export DOCKER_BUILDKIT=1

# (Optional) Create and use a dedicated buildx builder
docker buildx create --name gpu-builder --use
docker buildx inspect --bootstrap

# Build for linux/amd64
docker buildx build \
  --platform linux/amd64 \
  -t whisperx-gpu:latest \
  --load \
  -f Dockerfile .

# Run it with GPU access (on a Linux host)
docker run --gpus all \
  -v /local/audio:/data/audio \
  whisperx-gpu:latest \
  --input /data/audio/example.wav


