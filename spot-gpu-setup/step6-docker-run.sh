#!/usr/bin/env bash
#
# step6-docker-run.sh: WhisperX Docker runner with optional TF32 toggle.
#
# Usage:
#   TF32_ENABLE=1 ./step6-docker-run.sh
#
# Set TF32_ENABLE=1 to enable TensorFloat-32 acceleration (faster inference, slight numeric noise).
# Set TF32_ENABLE=0 (default) to disable TF32 for bit-exact reproducibility.

TF32_ENABLE=${TF32_ENABLE:-0}

# 1. Ensure input files exist
if [ ! -f audio.mp3 ]; then
  echo "🔄 Downloading audio.mp3..."
  wget -q https://2025-03-15-youtube-transcripts.s3.us-east-2.amazonaws.com/audio.mp3
fi
if [ ! -f test.webm ]; then
  echo "🔄 Downloading test.webm..."
  wget -q https://2025-03-15-youtube-transcripts.s3.us-east-2.amazonaws.com/test.webm
fi

# 2. Create host-side cache & output dirs
mkdir -p .cache/huggingface .cache/torch .config/matplotlib output

# 3. Generate entrypoint.py for in-container TF32 toggle
cat > entrypoint.py << 'EOF'
#!/usr/bin/env python3
import os
import torch
# Toggle TF32 based on TF32_ENABLE env var
if os.getenv('TF32_ENABLE','0') == '1':
    print("🛠 Enabling TF32 for faster GPU math...")
    torch.backends.cuda.matmul.allow_tf32 = True
    torch.backends.cudnn.allow_tf32 = True
else:
    print("🔒 TF32 disabled for reproducibility.")
# Launch WhisperX CLI with passed arguments
import sys
from whisperx.__main__ import cli
sys.exit(cli())
EOF
chmod +x entrypoint.py

# 4. Pull latest WhisperX image
docker pull ghcr.io/jim60105/whisperx:latest

# 5. Run WhisperX container with all caches & outputs redirected and TF32 toggle
docker run --gpus all -it \
  -v "$(pwd):/app" \
  -v "$(pwd)/.cache:/app/.cache" \
  -e TF32_ENABLE="$TF32_ENABLE" \
  -e HF_HOME=/app/.cache \
  -e HUGGINGFACE_HUB_CACHE=/app/.cache \
  -e XDG_CACHE_HOME=/app/.cache \
  -e TORCH_HOME=/app/.cache/torch \
  -e MPLCONFIGDIR=/app/.config/matplotlib \
  --workdir /app \
  --user "$(id -u):$(id -g)" \
  --rm \
  --entrypoint /app/entrypoint.py \
  ghcr.io/jim60105/whisperx:latest \
    --model large-v3 \
    --language en \
    --output_format srt \
    --print_progress True \
    --output_dir /app/output \
    /app/audio.mp3

