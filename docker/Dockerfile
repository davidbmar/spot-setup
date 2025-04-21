# Dockerfile for WhisperX on GPU-enabled EC2 instances
# Base on NVIDIA CUDA runtime

# 1. Use Docker BuildKit syntax for cross-platform builds
#    (this lets you build on macOS for linux/amd64)
# syntax = docker/dockerfile:1

FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04

# 2. Install system dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 3. Create and activate a virtual environment (optional)
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 4. Upgrade pip and install WhisperX + dependencies
RUN pip install --upgrade pip && \
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip install whisperx

# 5. Copy your transcription code into the image
WORKDIR /app
COPY ./transcribe.py ./

# 6. Set an entrypoint (adjust as needed)
ENTRYPOINT ["python3", "transcribe.py"]

