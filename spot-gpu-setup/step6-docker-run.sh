#!/usr/bin/bash
#docker pull davidbmar/whisperx:no_model

#get the audiofile.
wget https://2025-03-15-youtube-transcripts.s3.us-east-2.amazonaws.com/audio.mp3
wget https://2025-03-15-youtube-transcripts.s3.us-east-2.amazonaws.com/test.webm

#docker run --gpus all -it -v "$(pwd):/app" davidbmar/whisperx:no_model -- --model tiny --language en --output_format srt audio.mp3

# 1. Pull the stable base-en image
#docker pull ghcr.io/jim60105/whisperx:base-en
docker pull ghcr.io/jim60105/whisperx:latest

# 1. Make sure the config and output folders exist on your host
# mkdir -p .config/matplotlib output: ensures those folders exist and are owned by your user.
mkdir -p .config/matplotlib output


# 1. Create host-side cache & output dirs
mkdir -p .cache/huggingface .config/matplotlib output

# 1. Create the necessary host directories
mkdir -p .cache/huggingface .cache/torch .config/matplotlib output

# 2. Run WhisperX with all caches and output redirected to writable host folders
docker run --gpus all -it \
  -v "$(pwd):/app" \
  -v "$(pwd)/.cache:/app/.cache" \
  -e HF_HOME=/app/.cache \
  -e HUGGINGFACE_HUB_CACHE=/app/.cache \
  -e XDG_CACHE_HOME=/app/.cache \
  -e TORCH_HOME=/app/.cache/torch \
  -e MPLCONFIGDIR=/app/.config/matplotlib \
  --workdir /app \
  --user "$(id -u):$(id -g)" \
  --rm \
  ghcr.io/jim60105/whisperx:latest \
  -- --model large-v3 \
       --language en \
       --output_format srt \
       --print_progress True \
       --output_dir /app/output \
       /app/audio.mp3

