#!/bin/bash

# Define colors
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No color

echo -e "${BLUE}=== Host NVIDIA Driver Info ===${NC}"
nvidia-smi | grep "Driver Version"

echo ""
echo -e "${BLUE}CUDA Docker Image Options:${NC}"
echo "---------------------------"
echo -e "1. base    - Minimal CUDA runtime (smallest image)"
echo -e "2. runtime - Includes runtime dependencies and nvidia-smi"
echo -e "3. devel   - Full development environment (includes nvcc compiler)"

echo ""
read -p "Select an option to run (1=base, 2=runtime, 3=devel): " choice

# Select image tag based on input
case "$choice" in
  1)
    IMAGE="nvidia/cuda:11.8.0-base-ubuntu22.04"
    ;;
  2)
    IMAGE="nvidia/cuda:11.8.0-runtime-ubuntu22.04"
    ;;
  3)
    IMAGE="nvidia/cuda:11.8.0-devel-ubuntu22.04"
    ;;
  *)
    echo -e "${RED}Invalid option. Please choose 1, 2, or 3.${NC}"
    exit 1
    ;;
esac

echo ""
echo -e "${GREEN}Running ${IMAGE}...${NC}"
docker run --rm --gpus all "$IMAGE" nvidia-smi

echo ""
echo -e "${BLUE}=== Checking CUDA Toolkit Version inside container ===${NC}"
docker run --rm --gpus all "$IMAGE" bash -c "command -v nvcc >/dev/null && nvcc --version || echo -e '${YELLOW}nvcc not found in this image (no compiler tools installed).${NC}'"

