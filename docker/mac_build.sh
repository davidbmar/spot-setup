#!/bin/bash
# Build and Run WhisperX Image with Podman (macOS → linux/amd64)

# 1. Ensure you have Podman v4+ installed
#    (Homebrew: `brew install podman`)

# 2. Build the image for linux/amd64
podman build \
  --platform linux/amd64 \
  -t whisperx-gpu:latest \
  -f Dockerfile .

# 3. Verify the image architecture
podman image inspect whisperx-gpu:latest | grep Architecture

# 4. Run the container with GPU access on a GPU‑enabled host
#    Adjust device paths if needed for your NVIDIA setup
podman run --rm \
  --platform linux/amd64 \
  --security-opt label=disable \
  --device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm \
  -v /local/audio:/data/audio \
  whisperx-gpu:latest \
  --input /data/audio/example.wav

# 5. Push to ECR (optional)
#    Tag and push like you would with Docker
#    podman tag whisperx-gpu:latest <account>.dkr.ecr.<region>.amazonaws.com/whisperx-gpu:latest
#    podman push <account>.dkr.ecr.<region>.amazonaws.com/whisperx-gpu:latest

