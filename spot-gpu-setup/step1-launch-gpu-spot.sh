#!/usr/bin/env bash
set -euo pipefail
# — Configuration —
#AMI_ID="ami-0c8cb6d6f6dc127c9"  # Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04) in us-east-2
#AMI ID: ami-00e230f522a6b65dd # Name: Deep Learning AMI GPU PyTorch 2.0.0 (Amazon Linux 2) 20230524
AMI_ID="ami-0204a512d537abdc0" #us-east-2 Ubuntu, Name: Deep Learning AMI GPU PyTorch 1.13.1 (Ubuntu 20.04) 20230519
INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e"
SUBNET_ID="subnet-07efda88a184dd62d"
SPOT_PRICE="0.50"
KEY_NAME="g4dn.xlarge.david"
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem"
REGION="us-east-2"
chmod 400 "$KEY_PATH"
echo "✨ Using Ubuntu 22.04 LTS AMI with NVIDIA drivers in us-east-2: $AMI_ID"
echo "✨ Submitting Spot request with larger root volume (150 GiB)..."
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
    "UserData": "IyEvYmluL2Jhc2gKc2V0IC1ldW8gcGlwZWZhaWwKCiMgVXBkYXRlIHN5c3RlbQphcHQgdXBkYXRlCgojIEluc3RhbGwgRG9ja2VyIGlmIG5vdCBhbHJlYWR5IGluc3RhbGxlZAp3aGljaCBkb2NrZXIgfHwgKAogIGFwdCBpbnN0YWxsIC15IGRvY2tlci5pbwogIHN5c3RlbWN0bCBlbmFibGUgLS1ub3cgZG9ja2VyCiAgdXNlcm1vZCAtYUcgZG9ja2VyIHVidW50dQopCgojIEluc3RhbGwgTlZJRElBIENvbnRhaW5lciBUb29sa2l0IGlmIG5vdCBhbHJlYWR5IGluc3RhbGxlZApkaXN0cmlidXRpb249JCguIC9ldGMvb3MtcmVsZWFzZTtlY2hvICRJRCRWRVJTSU9OX0lEKQppZiAhIGNvbW1hbmQgLXYgbnZpZGlhLWN0ayA+L2Rldi9udWxsIDI+JjE7IHRoZW4KICBjdXJsIC1zIC1MIGh0dHBzOi8vbnZpZGlhLmdpdGh1Yi5pby9udmlkaWEtZG9ja2VyL2dwZ2tleSB8IGFwdC1rZXkgYWRkIC0KICBjdXJsIC1zIC1MIGh0dHBzOi8vbnZpZGlhLmdpdGh1Yi5pby9udmlkaWEtZG9ja2VyLyRkaXN0cmlidXRpb24vbnZpZGlhLWRvY2tlci5saXN0IHwgdGVlIC9ldGMvYXB0L3NvdXJjZXMubGlzdC5kL252aWRpYS1kb2NrZXIubGlzdAogIGFwdC1nZXQgdXBkYXRlCiAgYXB0LWdldCBpbnN0YWxsIC15IG52aWRpYS1jb250YWluZXItdG9vbGtpdAogIG52aWRpYS1jdGsgcnVudGltZSBjb25maWd1cmUgLS1ydW50aW1lPWRvY2tlcgogIHN5c3RlbWN0bCByZXN0YXJ0IGRvY2tlcgpmaQoKIyBQdWxsIHRoZSBXaGlzcGVyWCBkb2NrZXIgaW1hZ2UKZWNobyAiUHVsbGluZyBXaGlzcGVyWCBkb2NrZXIgaW1hZ2UuLi4iCmRvY2tlciBwdWxsIGdoY3IuaW8vamltNjAxMDUvd2hpc3Blcng6bm9fbW9kZWwKCiMgVmVyaWZ5IHRoYXQgR1BVIGlzIGF2YWlsYWJsZSB0byBEb2NrZXIKZWNobyAiVmVyaWZ5aW5nIEdQVSBhY2Nlc3MgaW4gRG9ja2VyLi4uIgpkb2NrZXIgcnVuIC0tZ3B1cyBhbGwgLS1ybSBudmlkaWEvY3VkYToxMi4yLjAtYmFzZS11YnVudHUyMi4wNCBudmlkaWEtc21pCgojIENyZWF0ZSBhIHRlc3QgZmlsZSB0byBpbmRpY2F0ZSBjb21wbGV0aW9uCmNhdCA+IC9ob21lL3VidW50dS9pbnN0YWxsYXRpb25fY29tcGxldGUudHh0IDw8RU9GCkluc3RhbGxhdGlvbiBjb21wbGV0ZWQgYXQgJChkYXRlKQpUaGUgc3lzdGVtIGlzIHJlYWR5IHRvIHJ1biBXaGlzcGVyWAoKIyBWZXJpZnkgdXNpbmc6CiMgbnZpZGlhLXNtaQojIGRvY2tlciBydW4gLS1ncHVzIGFsbCAtLXJtIG52aWRpYS9jdWRhOjEyLjIuMC1iYXNlLXVidW50dTIyLjA0IG52aWRpYS1zbWkKIwojIFJ1biBXaGlzcGVyWCB3aXRoOgojIGRvY2tlciBydW4gLS1ncHVzIGFsbCAtaXQgLXYgIiQocHdkKTovYXBwIiAtdiAiJChwd2QpLy5jYWNoZTovcm9vdC8uY2FjaGUiIGdoY3IuaW8vamltNjAxMDUvd2hpc3Blcng6bm9fbW9kZWwgLS0gLS1tb2RlbCB0aW55IC0tbGFuZ3VhZ2UgZW4gLS1vdXRwdXRfZm9ybWF0IHNydCAtLWNvbXB1dGVfdHlwZSBpbnQ4IC0tdmFkX2ZpbHRlciBGYWxzZSBhdWRpby5tcDMKRU9GCmNob3duIHVidW50dTp1YnVudHUgL2hvbWUvdWJ1bnR1L2luc3RhbGxhdGlvbl9jb21wbGV0ZS50eHQKCmVjaG8gIlNldHVwIGNvbXBsZXRlIgo="
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
echo "   ssh -i \"$KEY_PATH\" ubuntu@$PUBLIC_IP"
echo
echo "⚠️ Wait a few minutes for Docker and NVIDIA setup to complete"
echo
echo "After connecting, verify the installation with:"
echo "   nvidia-smi"
echo "   docker run --gpus all --rm nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi"
echo
echo "Then run WhisperX with:"
echo "   docker run --gpus all -it -v \"\$(pwd):/app\" -v \"\$(pwd)/.cache:/root/.cache\" ghcr.io/jim60105/whisperx:no_model -- --model tiny --language en --output_format srt --compute_type int8 --vad_filter False audio.mp3"
