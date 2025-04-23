#!/bin/bash
git clone https://github.com/your-org/spot-setup.git ~/spot-setup
cd ~/spot-setup/docker

# Build the WhisperX image
docker build -t whisperx-gpu:latest .

# Test run (on a GPU host)
docker run --gpus all whisperx-gpu:latest --input /path/to/file.wav
