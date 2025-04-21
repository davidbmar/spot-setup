#!/usr/bin/env bash
set -euo pipefail

# — Configuration —
AMI_ID="ami-04bd96eb1b67d9381"
INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e"
SUBNET_ID="subnet-07efda88a184dd62d"
SPOT_PRICE="0.50"
KEY_NAME="g4dn.xlarge.david"
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem"

# 1) Submit the Spot request and capture its Request ID
echo "✨ Submitting Spot request..."
SPOT_REQ_ID=$(aws ec2 request-spot-instances \
  --spot-price "$SPOT_PRICE" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification '{
    "ImageId":"'"$AMI_ID"'",
    "InstanceType":"'"$INSTANCE_TYPE"'",
    "KeyName":"'"$KEY_NAME"'",
    "NetworkInterfaces":[
      {
        "DeviceIndex":0,
        "SubnetId":"'"$SUBNET_ID"'",
        "AssociatePublicIpAddress": true,
        "Groups":["'"$SECURITY_GROUP_ID"'"]
      }
    ]
  }' \
  --query 'SpotInstanceRequests[0].SpotInstanceRequestId' \
  --output text)

# 2) Wait for the Spot request to be fulfilled
echo "⏳ Waiting for Spot request $SPOT_REQ_ID to be fulfilled..."
aws ec2 wait spot-instance-request-fulfilled \
  --spot-instance-request-ids "$SPOT_REQ_ID"

# 3) Get the EC2 instance ID
INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids "$SPOT_REQ_ID" \
  --query 'SpotInstanceRequests[0].InstanceId' \
  --output text)

# 4) Wait for the instance to be in running state
echo "⏳ Waiting for instance $INSTANCE_ID to enter running state..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# 5) Fetch its public IP address
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

# 6) Output (and invoke) the SSH command
echo
echo "✅ Instance $INSTANCE_ID is running with public IP: $PUBLIC_IP"
echo "🔑 SSH in with:"
echo "    ssh -i \"$KEY_PATH\" ec2-user@$PUBLIC_IP"
echo
# Optionally uncomment the next line to SSH automatically:
# ssh -i "$KEY_PATH" ec2-user@"$PUBLIC_IP"

