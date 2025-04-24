#!/usr/bin/env bash
set -euo pipefail

# — Configuration —
# Use a standard AMI like Amazon Linux 2023 (replace with the latest ID for your region)
# Find AL2023 AMIs here: https://aws.amazon.com/amazon-linux-2023/ami/
# Look for "ami-xxxxxxxxxxxxxxxxx (HVM, x86_64, GP2/GP3)"
# Example for us-east-2 (Ohio) - VERIFY THE LATEST ID!
AMI_ID="ami-060a84cbcb5c14844" # <<< REPLACE with actual AL2023 AMI ID for your region!
INSTANCE_TYPE="t3.large" # Sufficient CPU/RAM for building
SECURITY_GROUP_ID="sg-04f1a5465fe1b8f6e" # Your existing SG allowing SSH
SUBNET_ID="subnet-07efda88a184dd62d"     # Your existing subnet
SPOT_PRICE="0.10" # Adjust based on t3.large spot prices
KEY_NAME="g4dn.xlarge.david" # Your existing key pair name
KEY_PATH="$HOME/Desktop/login/g4dn.xlarge.david.pem" # Path to your key file

# --- Define and Base64 Encode User Data Script Content ---
# User data script to run on the instance upon launch
USER_DATA_SCRIPT_CONTENT=$(cat <<'EOF'
#!/bin/bash
# Ensure cloud-init logs are captured
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script..."

# Add ec2-user to docker group
echo "Adding ec2-user to docker group..."
sudo usermod -aG docker ec2-user

# Ensure docker is running and enabled on boot
echo "Enabling and starting docker service..."
sudo systemctl enable docker
sudo systemctl start docker

# Optional: Install git and other build tools needed for cloning/downloading code
echo "Installing git and wget..."
sudo dnf install -y git wget

echo "User data script finished."
EOF
)

# Base64 encode the User Data script content
# Use -w 0 for no line wrapping, required by AWS
BASE64_USER_DATA=$(echo -n "$USER_DATA_SCRIPT_CONTENT" | base64 -w 0)

# --- Ensure key file has correct permissions ---
if [ -f "$KEY_PATH" ]; then
    chmod 400 "$KEY_PATH"
else
    echo "Error: Key file not found at $KEY_PATH"
    exit 1
fi

# --- Construct the full launch specification JSON string using printf ---
# This is often more reliable than embedding variables directly in a single-quoted string
LAUNCH_SPEC_JSON=$(printf '{
  "ImageId":"%s",
  "InstanceType":"%s",
  "KeyName":"%s",
  "NetworkInterfaces":[{"DeviceIndex":0,"SubnetId":"%s","AssociatePublicIpAddress":true,"Groups":["%s"]}],
  "BlockDeviceMappings": [
    {
      "DeviceName": "/dev/xvda",
      "Ebs": {
        "VolumeSize": 100,
        "VolumeType": "gp3",
        "DeleteOnTermination": true
      }
    }
  ],
  "UserData": "%s"
}' \
"$AMI_ID" \
"$INSTANCE_TYPE" \
"$KEY_NAME" \
"$SUBNET_ID" \
"$SECURITY_GROUP_ID" \
"$BASE64_USER_DATA" \
)

# --- DEBUGGING ---
echo "--- Raw User Data Script Content ---"
echo "$USER_DATA_SCRIPT_CONTENT"
echo "------------------------------------"
echo "--- Base64 Encoded User Data ---"
echo "$BASE64_USER_DATA"
echo "--------------------------------"
echo "--- Launch Specification JSON being sent ---"
echo "$LAUNCH_SPEC_JSON"
echo "------------------------------------------"
# --- END DEBUGGING ---


echo "✨ Submitting Spot request for Docker Build Machine (CPU)..."

# Launch Specification is now built as a separate variable
SPOT_REQ_ID=$(aws ec2 request-spot-instances \
  --spot-price "$SPOT_PRICE" \
  --instance-count 1 \
  --type "one-time" \
  --launch-specification "$LAUNCH_SPEC_JSON" \
  --query 'SpotInstanceRequests[0].SpotInstanceRequestId' \
  --output text)

echo "⏳ Waiting for fulfillment of Spot request ID: $SPOT_REQ_ID..."

# Wait for the spot request to be fulfilled (an instance is launched)
aws ec2 wait spot-instance-request-fulfilled --spot-instance-request-ids "$SPOT_REQ_ID"

# Get the Instance ID from the fulfilled Spot request
INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
  --spot-instance-request-ids "$SPOT_REQ_ID" \
  --query 'SpotInstanceRequests[0].InstanceId' \
  --output text)

echo "⏳ Waiting for instance ID $INSTANCE_ID to enter running state..."
# Wait for the instance to be in the running state
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"

# Retrieve public IP and Availability Zone
read PUBLIC_IP AZ < <(aws ec2 describe-instances \
  --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[0].Instances[0].[PublicIpAddress,Placement.AvailabilityZone]' \
  --output text)

echo
echo "✅ Docker Build Machine (CPU) ready!"
echo "    Instance ID:        $INSTANCE_ID"
echo "    Public IP:          $PUBLIC_IP"
echo "    Availability Zone:  $AZ"
echo
echo "🔑 Connect with:"
echo "    ssh -i \"$KEY_PATH\" ec2-user@$PUBLIC_IP"

# --- Optional: Instructions after connection ---
echo
echo "Once connected, you can navigate to your project directory, then run:"
echo "    git clone <your_repo_url>"
echo "    cd <your_repo_dir>"
echo "    docker build -t your-image-name ."
echo "    docker push your-image-name"
