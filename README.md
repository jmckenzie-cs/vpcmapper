# AWS VPC Resource Mapper

A simple bash script that maps AWS VPC resources (subnets and security groups) to a JSON output format.

## Features

- Maps VPC ID, subnets, and security groups
- Uses resource Name tags as keys (falls back to resource IDs)
- Clean JSON output format
- Regional support

## Prerequisites

- AWS CLI installed and configured
- `jq` for JSON processing (`brew install jq`)
- Valid AWS credentials with EC2 describe permissions

## Installation

```bash
git clone <repository-url>
cd vpcmapper
chmod +x vpc_resource_mapper.sh
```

## Usage

```bash
# Single VPC (uses default region from AWS config)
./vpc_resource_mapper.sh vpc-1234567890abcdef0

# Single VPC with specific region
./vpc_resource_mapper.sh vpc-1234567890abcdef0 us-east-1

# Multiple VPCs in different regions
./vpc_resource_mapper.sh vpc-1234567890abcdef0 us-east-1 vpc-0fedcba9876543210 us-west-2

# Multiple VPCs, mix of specified and default regions
./vpc_resource_mapper.sh vpc-1234567890abcdef0 vpc-0fedcba9876543210 us-west-2

# Save output to file
./vpc_resource_mapper.sh vpc-1234567890abcdef0 us-east-1 > vpc-map.json
```

## Output Format

Single VPC:
```json
{
  "us-east-1": {
    "vpc": "vpc-11223344556677889",
    "scanner_subnet": "subnet-11223344556677887",
    "scanner_sg": "sg-11223344556677888",
    "db_subnet_a": "subnet-11223344556677888",
    "db_subnet_b": "subnet-11223344556677889",
    "db_sg": "sg-11223344556677889"
  }
}
```

Multiple VPCs across regions:
```json
{
  "us-east-1": {
    "vpc": "vpc-11223344556677889",
    "scanner_subnet": "subnet-11223344556677887",
    "scanner_sg": "sg-11223344556677888"
  },
  "us-west-2": {
    "vpc": "vpc-99887766554433221",
    "web_subnet": "subnet-99887766554433220",
    "app_sg": "sg-99887766554433221"
  }
}
```

Keys are taken from the Name tag of each resource. If no Name tag exists, the resource ID is used as the key.

## Required AWS Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups"
      ],
      "Resource": "*"
    }
  ]
}
```

## License

MIT
