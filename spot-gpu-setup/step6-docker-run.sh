#!/usr/bin/bash
#docker pull davidbmar/whisperx:no_model

#get the audiofile.
wget https://2025-03-15-youtube-transcripts.s3.us-east-2.amazonaws.com/audio.mp3
wget https://2025-03-15-youtube-transcripts.s3.us-east-2.amazonaws.com/test.webm

#docker run --gpus all -it -v "$(pwd):/app" davidbmar/whisperx:no_model -- --model tiny --language en --output_format srt audio.mp3

# 1. Pull the stable base-en image
docker pull ghcr.io/jim60105/whisperx:base-en

# 2. Run WhisperX on 'audio.mp3' and output SRT subtitles to your current directory
docker run --gpus all -it \
  -v "$(pwd):/app" \
  --rm \
  ghcr.io/jim60105/whisperx:base-en \
  -- --output_format srt /app/audio.mp3


