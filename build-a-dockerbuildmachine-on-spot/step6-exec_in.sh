# Option A: Docker exec (no SSH server/config needed)
# 1. List your running containers
docker ps
# 2. Pick your container’s ID or name (e.g. "whisperx_worker") and run:
docker exec -it <container_id_or_name> /bin/bash

# Option B: SSH into the container over TCP
# (Only works if you started the container with something like -p 2222:22)
# 1. Verify port mapping:
docker ps
#    Look for "0.0.0.0:2222->22/tcp" or similar in the PORTS column
# 2. SSH in:
ssh root@localhost -p 2222
#    — or, if you mapped to the EC2 private IP: 
ssh root@<EC2_PRIVATE_IP> -p 2222

