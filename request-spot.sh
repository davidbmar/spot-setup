#!/usr/bin/env bash
# Replace the placeholders below before running
AMI_ID=ami-0123456789abcdef0    # e.g. the latest AWS Deep Learning AMI in your region
INSTANCE_TYPE=g4dn.xlarge
KEY_NAME=my-key-pair            # your EC2 key pair
SECURITY_GROUP_ID=sg-01234567   # a GPU‑enabled SG allowing SSH (port 22)
SUBNET_ID=subnet-89abcdef0      # a subnet in your VPC
SPOT_PRICE=0.50                 # max hourly price you’re willing to pay

aws ec2 request-spot-instances \
  --spot-price "$SPOT_PRICE" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification "{
    \"ImageId\":\"$AMI_ID\",
    \"InstanceType\":\"$INSTANCE_TYPE\",
    \"KeyName\":\"$KEY_NAME\",
    \"SecurityGroupIds\":[\"$SECURITY_GROUP_ID\"],
    \"SubnetId\":\"$SUBNET_ID\"
  }"
