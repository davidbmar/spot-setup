#!/usr/bin/env bash
set -euo pipefail
# — Configuration —
# Hardcoded Amazon Linux 2023 AMI for us-east-2
AMI_ID="ami-0430580de6244e02e"  # Amazon Linux 2023 in us-east-2
INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e"
SUBNET_ID="subnet-07efda88a184dd62d"
SPOT_PRICE="0.50"
KEY_NAME="g4dn.xlarge.david"
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem"
REGION="us-east-2"
chmod 400 "$KEY_PATH"
echo "✨ Using Amazon Linux 2023 AMI ID in us-east-2: $AMI_ID"
echo "✨ Submitting Spot request with larger root volume (150 GiB)..." # Modified echo message
SPOT_REQ_ID=$(aws ec2 request-spot-instances \
  --spot-price "$SPOT_PRICE" \
  --instance-count 1 \
  --type "one-time" \
  --region $REGION \
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
    ],
    "UserData": "IyEvYmluL2Jhc2gKIyBVcGRhdGUgc3lzdGVtIHBhY2thZ2VzCnN1ZG8gZG5mIHVwZGF0ZSAteSAmJiBzdWRvIGRuZiBpbnN0YWxsIC15IGRrbXMKc3VkbyBzeXN0ZW1jdGwgZW5hYmxlIC0tbm93IGRrbXMKIyBJbnN0YWxsIGtlcm5lbCBkZXZlbG9wbWVudCBwYWNrYWdlcwppZiAodW5hbWUgLXIgfCBncmVwIC1xIF42LjEyLik7IHRoZW4KICBzdWRvIGRuZiBpbnN0YWxsIC15IGtlcm5lbC1kZXZlbC0kKHVuYW1lIC1yKSBrZXJuZWw2LjEyLW1vZHVsZXMtZXh0cmEKZWxzZQogIHN1ZG8gZG5mIGluc3RhbGwgLXkga2VybmVsLWRldmVsLSQodW5hbWUgLXIpIGtlcm5lbC1tb2R1bGVzLWV4dHJhCmZpCnN1ZG8gZG5mIGluc3RhbGwgLXkgZG9ja2VyCnN1ZG8gc3lzdGVtY3RsIGVuYWJsZSAtLW5vdyBkb2NrZXIKIyBBZGQgTlZJRElBIHJlcG8gYW5kIGluc3RhbGwgZHJpdmVycwpzdWRvIGRuZiBjb25maWctbWFuYWdlciAtLWFkZC1yZXBvIGh0dHBzOi8vZGV2ZWxvcGVyLmRvd25sb2FkLm52aWRpYS5jb20vY29tcHV0ZS9jdWRhL3JlcG9zL2FtenIyMDIzL3g4Nl82NC9jdWRhLWFtenIyMDIzLnJlcG8Kc3VkbyBkbmYgaW5zdGFsbCAteSBudmlkaWEtZHJpdmVyLWxhdGVzdC1keG4ga2VybmVsLWRldmVsLXVuYW1lIC1yCiMgSW5zdGFsbCBDVURBIFRvb2xraXQgMTIuOApzdWRvIGRuZiBpbnN0YWxsIC15IGN1ZGEtdG9vbGtpdC0xMi04CiMgSW5zdGFsbCBDb250YWluZXIgVG9vbGtpdApzdWRvIGRuZiBjb25maWctbWFuYWdlciAtLWFkZC1yZXBvIGh0dHBzOi8vbnZpZGlhLmdpdGh1Yi5pby9saWJudmlkaWEtY29udGFpbmVyL3N0YWJsZS9ycG0vbnZpZGlhLWNvbnRhaW5lci10b29sa2l0LnJlcG8Kc3VkbyBkbmYgaW5zdGFsbCAteSBudmlkaWEtY29udGFpbmVyLXRvb2xraXQKc3VkbyBudmlkaWEtY3RrIHJ1bnRpbWUgY29uZmlndXJlIC0tcnVudGltZT1kb2NrZXIKc3VkbyBzeXN0ZW1jdGwgcmVzdGFydCBkb2NrZXIK"
  }' \
  --query 'SpotInstanceRequests[0].SpotInstanceRequestId' \
  --output text)
echo "⏳ Waiting for fulfillment..."
aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids "$SPOT_REQ_ID" --region $REGION
INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids "$SPOT_REQ_ID" \
  --region $REGION \
  --query 'SpotInstanceRequests[0].InstanceId' \
  --output text)
echo "⏳ Waiting for instance to run..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region $REGION
# Retrieve public IP and AZ
read PUBLIC_IP AZ < <(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --region $REGION \
  --query 'Reservations[0].Instances[0].[PublicIpAddress,Placement.AvailabilityZone]' \
  --output text)
# Fetch the latest spot price for this type in that AZ
CURRENT_SPOT_PRICE=$(aws ec2 describe-spot-price-history \
  --instance-types "$INSTANCE_TYPE" \
  --product-descriptions "Linux/UNIX" \
  --availability-zone "$AZ" \
  --region $REGION \
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
echo "⚠️ Wait about 5 minutes for the setup script to complete installation of NVIDIA drivers and CUDA 12.8"
echo
echo "After connecting, verify the installation with:"
echo "   nvidia-smi"
echo "   nvcc --version"
echo
echo "Then run WhisperX with:"
echo "   docker run --gpus all -it -v \"\$(pwd):/app\" -v \"\$(pwd)/.cache:/root/.cache\" ghcr.io/jim60105/whisperx:no_model -- --model tiny --language en --output_format srt --compute_type int8 --vad_filter False audio.mp3"
