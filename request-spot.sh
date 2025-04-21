#!/usr/bin/env bash
set -euo pipefail

# — Non‑sensitive, safe to commit —
AMI_ID="ami-04bd96eb1b67d9381"
INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e"
SUBNET_ID="subnet-07efda88a184dd62d"
SPOT_PRICE="0.50"

# — Hard‑coded key pair name & path to your .pem —
KEY_NAME="g4dn.xlarge.david"
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem"

# Submit the Spot request with a public IP
aws ec2 request-spot-instances \
  --spot-price "$SPOT_PRICE" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification '{
    "ImageId": "'"$AMI_ID"'",
    "InstanceType": "'"$INSTANCE_TYPE"'",
    "KeyName": "'"$KEY_NAME"'",
    "NetworkInterfaces": [
      {
        "DeviceIndex": 0,
        "SubnetId": "'"$SUBNET_ID"'",
        "AssociatePublicIpAddress": true,
        "Groups": ["'"$SECURITY_GROUP_ID"'"]
      }
    ]
  }'

echo
echo "✅ Spot request submitted."
echo "Once it’s running, fetch its public IP and connect with:"
echo "  ssh -i \"$KEY_PATH\" ec2-user@<public-ip>"

