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


chmod 400 "$KEY_PATH"

echo "✨ Submitting Spot request with larger root volume (150 GiB)..."
# Note: Launch Specification below includes BlockDeviceMappings for 150GiB gp3 root volume
SPOT_REQ_ID=$(aws ec2 request-spot-instances \
  --spot-price "$SPOT_PRICE" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification '{
    "ImageId":"'"$AMI_ID"'",
    "InstanceType":"'"$INSTANCE_TYPE"'",
    "KeyName":"'"$KEY_NAME"'",
    "NetworkInterfaces":[{"DeviceIndex":0,"SubnetId":"'"$SUBNET_ID"'","AssociatePublicIpAddress":true,"Groups":["'"$SECURITY_GROUP_ID"'"]}],
    "BlockDeviceMappings": [
      {
        "DeviceName": "/dev/sda1",
        "Ebs": {
          "VolumeSize": 150,
          "VolumeType": "gp3",
          "DeleteOnTermination": true
        }
      }
    ]
  }' \
  --query 'SpotInstanceRequests[0].SpotInstanceRequestId' \
  --output text) # This might be around line 54 in your script

echo "⏳ Waiting for fulfillment..."

aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids "$SPOT_REQ_ID"

INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids "$SPOT_REQ_ID" \
  --query 'SpotInstanceRequests[0].InstanceId' \
  --output text)

echo "⏳ Waiting for instance to run..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# Retrieve public IP and AZ
read PUBLIC_IP AZ < <(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].[PublicIpAddress,Placement.AvailabilityZone]' \
  --output text)

# Fetch the latest spot price for this type in that AZ
CURRENT_SPOT_PRICE=$(aws ec2 describe-spot-price-history \
  --instance-types "$INSTANCE_TYPE" \
  --product-descriptions "Linux/UNIX" \
  --availability-zone "$AZ" \
  --start-time "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --max-items 1 \
  --query 'SpotPriceHistory[0].SpotPrice' \
  --output text)

echo
echo "✅ Spot instance ready!"
echo "   Instance ID:         $INSTANCE_ID"
echo "   Public IP:           $PUBLIC_IP"
echo "   Availability Zone:   $AZ"
echo "   Current spot price:  \$$CURRENT_SPOT_PRICE per hour"
echo
echo "🔑 Connect with:"
echo "   ssh -i \"$KEY_PATH\" ec2-user@$PUBLIC_IP"

