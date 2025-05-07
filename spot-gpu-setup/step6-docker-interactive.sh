#!/usr/bin/env bash
#
# final-docker-interactive.sh: Properly configured WhisperX container with interactive shell
#
# Usage:
#   ./final-docker-interactive.sh
#
# Set TF32_ENABLE=1 to enable TensorFloat-32 acceleration (faster inference, slight numeric noise).
# Set TF32_ENABLE=0 (default) to disable TF32 for bit-exact reproducibility.

TF32_ENABLE=${TF32_ENABLE:-0}

# 1. Ensure input files exist (optional)
if [ ! -f audio.mp3 ]; then
  echo "🔄 Downloading audio.mp3..."
  wget -q https://2025-03-15-youtube-transcripts.s3.us-east-2.amazonaws.com/audio.mp3
fi

# 2. Create host-side directories with proper permissions
echo "🔧 Setting up directories with proper permissions..."
mkdir -p output .cache/huggingface .cache/torch .config/matplotlib
chmod -R 777 output .cache .config

# 3. Create shell setup script
cat > docker_setup.sh << 'EOF'
#!/bin/bash
# Setup script for WhisperX container

# Configure TF32 if enabled
if [ "$TF32_ENABLE" = "1" ]; then
  echo "🛠 Enabling TF32 for faster GPU math..."
  # Create a small Python script to enable TF32
  cat > /tmp/enable_tf32.py << 'PYEOF'
import torch
torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True
print("TF32 enabled")
PYEOF
  # Run it once now
  python /tmp/enable_tf32.py
else
  echo "🔒 TF32 disabled for reproducibility."
fi

# Create aliases for WhisperX
cat > ~/.bash_aliases << 'ALIASEOF'
# WhisperX shortcuts
alias wx-tiny='python -m whisperx --model tiny --language en --output_format srt --output_dir /app/output'
alias wx-base='python -m whisperx --model base --language en --output_format srt --output_dir /app/output'
alias wx-small='python -m whisperx --model small --language en --output_format srt --output_dir /app/output'
alias wx-medium='python -m whisperx --model medium --language en --output_format srt --output_dir /app/output'
alias wx-large='python -m whisperx --model large-v3 --language en --output_format srt --output_dir /app/output'
ALIASEOF

# Source aliases
source ~/.bash_aliases

# Print welcome message and instructions
echo ""
echo "🔍 WhisperX Shortcuts:"
echo "   wx-tiny audio.mp3    - Run tiny model"
echo "   wx-base audio.mp3    - Run base model"
echo "   wx-small audio.mp3   - Run small model"
echo "   wx-medium audio.mp3  - Run medium model"
echo "   wx-large audio.mp3   - Run large-v3 model"
echo ""
echo "📋 Example full commands:"
echo "   python -m whisperx --model large-v3 --language en --output_format srt --output_dir /app/output audio.mp3"
echo ""
echo "💡 To enable TF32 (faster math but less precision):"
echo "   python -c 'import torch; torch.backends.cuda.matmul.allow_tf32=True; torch.backends.cudnn.allow_tf32=True'"
echo ""
echo "📁 Your output files will be saved to the ./output directory"
echo ""
EOF
chmod +x docker_setup.sh

# 4. Pull latest WhisperX image
echo "🔄 Pulling latest WhisperX image..."
docker pull ghcr.io/jim60105/whisperx:latest

echo "🚀 Launching WhisperX container in interactive mode..."
echo "📋 The container will have shortcuts like wx-large, wx-medium, etc."
echo "🔍 Press Ctrl+D or type 'exit' to exit the container"
echo ""

# 5. Run WhisperX container with bash as entrypoint
# We'll execute the setup script inside as part of the bash command
docker run --gpus all -it \
  -v "$(pwd):/app" \
  -e TF32_ENABLE="$TF32_ENABLE" \
  -e HF_HOME=/app/.cache/huggingface \
  -e HUGGINGFACE_HUB_CACHE=/app/.cache/huggingface \
  -e XDG_CACHE_HOME=/app/.cache \
  -e TORCH_HOME=/app/.cache/torch \
  -e MPLCONFIGDIR=/app/.cache/matplotlib \
  --workdir /app \
  --entrypoint /bin/bash \
  --rm \
  ghcr.io/jim60105/whisperx:latest \
  -c "source /app/docker_setup.sh && exec /bin/bash"

echo "Container exited. Your processed files (if any) are in the ./output directory."
