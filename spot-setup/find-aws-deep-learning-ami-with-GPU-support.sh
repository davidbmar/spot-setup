#!/bin/bash
# 1. Find the most recent AWS Deep Learning AMI with GPU support:
aws ec2 describe-images \
  --owners amazon \
  --filters \
    "Name=name,Values=Deep Learning AMI GPU PyTorch*" \
    "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text
