#!/usr/bin/env bash
set -euo pipefail
# — Configuration —
# Ubuntu 20.04 LTS AMI for us-east-2
AMI_ID="ami-051197a6466e8a8ac"  # Ubuntu 20.04 LTS in us-east-2
INSTANCE_TYPE="g4dn.xlarge"
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e"
SUBNET_ID="subnet-07efda88a184dd62d"
SPOT_PRICE="0.50"
KEY_NAME="g4dn.xlarge.david"
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem"
REGION="us-east-2"
chmod 400 "$KEY_PATH"
echo "✨ Using Ubuntu 20.04 LTS AMI ID in us-east-2: $AMI_ID"
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
    "UserData": "IyEvYmluL2Jhc2gKIyBVcGRhdGUgc3lzdGVtIHBhY2thZ2VzCnNldCAtZXVvIHBpcGVmYWlsCmFwdCB1cGRhdGUKYXB0IGluc3RhbGwgLXkgY3VybCBidWlsZC1lc3NlbnRpYWwgZGttcwoKIyBJbnN0YWxsIE5WSURJQSBkcml2ZXJzCmFwdCBpbnN0YWxsIC15IG52aWRpYS1kcml2ZXItNTcwCgojIEluc3RhbGwgQ1VEQSBUb29sa2l0IDEyLjcKd2dldCBodHRwczovL2RldmVsb3Blci5kb3dubG9hZC5udmlkaWEuY29tL2NvbXB1dGUvY3VkYS9yZXBvcy91YnVudHUyMDA0L3g4Nl82NC9jdWRhLWtleXJpbmdfMS4xLTFfYWxsLmRlYgpkcGtnIC1pIGN1ZGEta2V5cmluZ18xLjEtMV9hbGwuZGViCmFwdC1nZXQgdXBkYXRlCmFwdC1nZXQgaW5zdGFsbCAteSBjdWRhLXRvb2xraXQtMTItNwoKIyBJbnN0YWxsIERvY2tlcgphcHQgaW5zdGFsbCAteSBkb2NrZXIuaW8Kc3lzdGVtY3RsIGVuYWJsZSAtLW5vdyBkb2NrZXIKdXNlcm1vZCAtYUcgZG9ja2VyIHVidW50dQoKIyBJbnN0YWxsIE5WSURJQSBDb250YWluZXIgVG9vbGtpdApkaXN0cmlidXRpb249JCguIC9ldGMvb3MtcmVsZWFzZTtlY2hvICRJRCRWRVJTSU9OX0lEKQpjdXJsIC1zIC1MIGh0dHBzOi8vbnZpZGlhLmdpdGh1Yi5pby9udmlkaWEtZG9ja2VyL2dwZ2tleSB8IGFwdC1rZXkgYWRkIC0KY3VybCAtcyAtTCBodHRwczovL252aWRpYS5naXRodWIuaW8vbnZpZGlhLWRvY2tlci8kZGlzdHJpYnV0aW9uL252aWRpYS1kb2NrZXIubGlzdCB8IHRlZSAvZXRjL2FwdC9zb3VyY2VzLmxpc3QuZC9udmlkaWEtZG9ja2VyLmxpc3QKYXB0LWdldCB1cGRhdGUKYXB0LWdldCBpbnN0YWxsIC15IG52aWRpYS1jb250YWluZXItdG9vbGtpdApudmlkaWEtY3RrIHJ1bnRpbWUgY29uZmlndXJlIC0tcnVudGltZT1kb2NrZXIKc3lzdGVtY3RsIHJlc3RhcnQgZG9ja2VyCgojIFNldCBlbnZpcm9ubWVudCB2YXJpYWJsZXMKY2F0ID4+IC9ob21lL3VidW50dS8uYmFzaHJjIDw8RU9GCgojIENVREEgc2V0dXAKZXhwb3J0IFBBVEg9IiRQQVRIOi91c3IvbG9jYWwvY3VkYS1ub3ZhL2JpbiIKZXhwb3J0IExEX0xJQlJBUllfUEFUSD0iJExEX0xJQlJBUllfUEFUSDovdXNyL2xvY2FsL2N1ZGEtbm92YS9saWI2NCIKRU9GCgojIEVuc3VyZSB1YnVudHUgdXNlciBvd25zIHRoZSBmaWxlcwpjaG93biAtUiB1YnVudHU6dWJ1bnR1IC9ob21lL3VidW50dS8uYmFzaHJjCgojIENyZWF0ZSBhIHRlc3QgZmlsZSB0byBpbmRpY2F0ZSBjb21wbGV0aW9uCmNhdCA+IC9ob21lL3VidW50dS9pbnN0YWxsYXRpb25fY29tcGxldGUudHh0IDw8RU9GCkluc3RhbGxhdGlvbiBjb21wbGV0ZWQgYXQgJChkYXRlKQpSZWJvb3QgdGhlIHN5c3RlbSB0byBlbnN1cmUgYWxsIGRyaXZlcnMgYXJlIGxvYWRlZCBwcm9wZXJseS4KRU9GCmNob3duIHVidW50dTp1YnVudHUgL2hvbWUvdWJ1bnR1L2luc3RhbGxhdGlvbl9jb21wbGV0ZS50eHQKCiMgUmVib290IHRvIGFwcGx5IGFsbCBjaGFuZ2VzCnJlYm9vdA=="
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
echo "⚠️ Wait about 5-10 minutes for the setup script to complete installation of NVIDIA drivers and CUDA 12.7"
echo
echo "After connecting, verify the installation with:"
echo "   nvidia-smi"
echo "   nvcc --version"
echo
echo "Then run WhisperX with:"
echo "   docker run --gpus all -it -v \"\$(pwd):/app\" -v \"\$(pwd)/.cache:/root/.cache\" ghcr.io/jim60105/whisperx:no_model -- --model tiny --language en --output_format srt --compute_type int8 --vad_filter False audio.mp3"
