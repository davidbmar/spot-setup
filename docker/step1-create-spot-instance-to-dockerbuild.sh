#!/usr/bin/env bash
set -euo pipefail

# — Configuration —
AMI_ID="ami-04bd96eb1b67d9381"          # GPU‑ready AMI (DLAMI or Ubuntu)
INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e"
SUBNET_ID="subnet-07efda88a184dd62d"
SPOT_PRICE="0.50"
KEY_NAME="g4dn.xlarge.david"
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem"

chmod 400 "$KEY_PATH"

echo "✨ Submitting Spot request..."
SPOT_REQ_ID=$(aws ec2 request-spot-instances \
  --spot-price "$SPOT_PRICE" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification '{
    "ImageId":"'"$AMI_ID"'",
    "InstanceType":"'"$INSTANCE_TYPE"'",
    "KeyName":"'"$KEY_NAME"'",
    "NetworkInterfaces":[{"DeviceIndex":0,"SubnetId":"'"$SUBNET_ID"'","AssociatePublicIpAddress":true,"Groups":["'"$SECURITY_GROUP_ID"'"]}]
  }' \
  --query 'SpotInstanceRequests[0].SpotInstanceRequestId' \
  --output text)

echo "⏳ Waiting for fulfillment..."
aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids "$SPOT_REQ_ID"

INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids "$SPOT_REQ_ID" \
  --query 'SpotInstanceRequests[0].InstanceId' \
  --output text)

echo "⏳ Waiting for instance to run..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

echo
echo "✅ Spot instance ready!"
echo "   Instance ID: $INSTANCE_ID"
echo "   Public IP:   $PUBLIC_IP"
echo
echo "🔑 Connect with:"
echo "   ssh -i \"$KEY_PATH\" ec2-user@$PUBLIC_IP"

