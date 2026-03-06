#!/bin/bash
#
# VPC Resource Mapper - Simplified
# Outputs VPC with subnets and security groups in JSON format
#

set -e

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed." >&2
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Install with: brew install jq" >&2
    exit 1
fi

# Usage
if [ $# -lt 1 ]; then
    echo "Usage: $0 <vpc-id> [region]" >&2
    echo "" >&2
    echo "Example:" >&2
    echo "  $0 vpc-12345678" >&2
    echo "  $0 vpc-12345678 us-east-1" >&2
    exit 1
fi

VPC_ID=$1
REGION=${2:-$(aws configure get region)}

# Validate VPC ID format
if [[ ! $VPC_ID =~ ^vpc- ]]; then
    echo "Error: Invalid VPC ID format: $VPC_ID" >&2
    exit 1
fi

# Set region flag if provided
REGION_FLAG=""
if [ -n "$REGION" ]; then
    REGION_FLAG="--region $REGION"
fi

echo "Fetching resources for VPC: $VPC_ID in region: $REGION" >&2
echo "" >&2

# Initialize the result
RESULT="{}"
RESULT=$(echo "$RESULT" | jq --arg region "$REGION" --arg vpc "$VPC_ID" '.[$region] = {vpc: $vpc}')

# Get Subnets
echo "Fetching subnets..." >&2
SUBNETS_RAW=$(aws ec2 describe-subnets $REGION_FLAG --filters "Name=vpc-id,Values=$VPC_ID" --output json 2>&1)

if echo "$SUBNETS_RAW" | jq empty 2>/dev/null; then
    # Valid JSON
    SUBNET_COUNT=$(echo "$SUBNETS_RAW" | jq '.Subnets | length')
    echo "Found $SUBNET_COUNT subnets" >&2

    # Process each subnet
    while IFS= read -r subnet; do
        SUBNET_ID=$(echo "$subnet" | jq -r '.SubnetId')
        NAME_TAG=$(echo "$subnet" | jq -r '.Tags // [] | map(select(.Key == "Name")) | .[0].Value // empty')

        if [ -n "$NAME_TAG" ]; then
            KEY="$NAME_TAG"
        else
            KEY="$SUBNET_ID"
        fi

        RESULT=$(echo "$RESULT" | jq --arg region "$REGION" --arg key "$KEY" --arg value "$SUBNET_ID" '.[$region][$key] = $value')
    done < <(echo "$SUBNETS_RAW" | jq -c '.Subnets[]')
else
    echo "Warning: Invalid JSON response for subnets" >&2
fi

# Get Security Groups
echo "Fetching security groups..." >&2
SGS_RAW=$(aws ec2 describe-security-groups $REGION_FLAG --filters "Name=vpc-id,Values=$VPC_ID" --output json 2>&1)

if echo "$SGS_RAW" | jq empty 2>/dev/null; then
    # Valid JSON
    SG_COUNT=$(echo "$SGS_RAW" | jq '.SecurityGroups | length')
    echo "Found $SG_COUNT security groups" >&2

    # Process each security group
    while IFS= read -r sg; do
        SG_ID=$(echo "$sg" | jq -r '.GroupId')
        NAME_TAG=$(echo "$sg" | jq -r '.Tags // [] | map(select(.Key == "Name")) | .[0].Value // empty')

        if [ -n "$NAME_TAG" ]; then
            KEY="$NAME_TAG"
        else
            KEY="$SG_ID"
        fi

        RESULT=$(echo "$RESULT" | jq --arg region "$REGION" --arg key "$KEY" --arg value "$SG_ID" '.[$region][$key] = $value')
    done < <(echo "$SGS_RAW" | jq -c '.SecurityGroups[]')
else
    echo "Warning: Invalid JSON response for security groups" >&2
fi

# Output JSON
echo "$RESULT"

echo "" >&2
echo "✓ Resource map generated successfully!" >&2
