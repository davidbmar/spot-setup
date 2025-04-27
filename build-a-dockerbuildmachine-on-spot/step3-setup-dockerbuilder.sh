# Update and install Docker
sudo yum -y update
sudo amazon-linux-extras enable docker
sudo yum install -y docker
sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user

# 1. Ensure the 'docker' group exists:
sudo groupadd docker 2>/dev/null

# 2. Add ec2-user to the docker group:
sudo usermod -aG docker ec2-user

# 3. Apply the new group membership immediately:
newgrp docker

# 4. Verify you can run Docker without sudo:
docker run --rm hello-world


## NVIDIA Container Toolkit
#distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
#curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo rpm --import -
#curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list \
#  | sudo tee /etc/yum.repos.d/nvidia-docker.repo
#sudo yum install -y nvidia-docker2
sudo systemctl restart docker

