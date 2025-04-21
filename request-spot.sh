#!/usr/bin/env bash
set -euo pipefail

# — Non‑sensitive, safe to commit —
AMI_ID="ami-04bd96eb1b67d9381"
INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-01234567"
SUBNET_ID="subnet-89abcdef0"
SPOT_PRICE="0.50"
KEY_PATH="$HOME/Desktop/login/"
KEY_NAME="g4dn.xlarge.david"

# Submit the Spot request
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

# Hint for next step
echo
echo "✅ Spot request submitted."
echo "When it’s running, fetch its public IP and connect with:"
echo "  ssh -i \"$KEY_PATH\" ec2-user@<instance-ip>"

