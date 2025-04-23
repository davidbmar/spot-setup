#!/bin/bash
# 1. On your EC2 GPU instance, install Docker (Amazon Linux 2)
sudo amazon-linux-extras install docker -y
sudo systemctl enable --now docker
# Add your user to the docker group (you may need to log out and back in for this to take effect)
sudo usermod -aG docker $USER

# 2. Install the NVIDIA Container Toolkit
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
sudo yum install -y nvidia-container-toolkit
sudo systemctl restart docker

# 3. Pull your image from Docker Hub
docker pull davidbmar/whisper-runpod:latest

# 4. Run the container with GPU access
docker run --gpus all --rm -it \
  -v /home/ec2-user/models:/app/models \
  -e AWS_REGION=us-east-1 \
  davidbmar/whisper-runpod:latest \
  /bin/bash
