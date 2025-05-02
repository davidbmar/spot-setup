#!/usr/bin/env bash
set -euo pipefail
# — Configuration —
# Use the AWS CLI to get the latest Deep Learning Base OSS Nvidia Driver AMI ID
# This will be replaced with the actual AMI ID from the command below
AMI_ID=$(aws ec2 describe-images --region us-east-1 --owners amazon \
  --filters 'Name=name,Values=Deep Learning Base OSS Nvidia Driver AMI (Amazon Linux 2023)*' 'Name=state,Values=available' \
  --query 'reverse(sort_by(Images, &CreationDate))[:1].ImageId' \
  --output text)

INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e"
SUBNET_ID="subnet-07efda88a184dd62d"
SPOT_PRICE="0.50"
KEY_NAME="g4dn.xlarge.david"
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem"
chmod 400 "$KEY_PATH"
echo "✨ Using AMI ID: $AMI_ID"
echo "✨ Submitting Spot request with larger root volume (150 GiB)..." # Modified echo message
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
  --output text)
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
echo
echo "After connecting, run the setup commands for WhisperX:"
echo "sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/amzn2023/x86_64/cuda-amzn2023.repo"
echo "sudo dnf install -y cuda-toolkit-12-8 nvidia-container-toolkit"
echo "sudo systemctl restart docker"
