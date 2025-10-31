# AWS VPC Terraform Module

This module creates a complete AWS VPC infrastructure with public and private subnets, internet gateway, route tables, and security groups.

## Features

- VPC with configurable CIDR block
- Auto-generated or custom public/private subnets
- Internet Gateway for public subnet access
- Route tables with proper associations
- Security group with common rules (SSH, HTTP, HTTPS)
- Multi-AZ subnet distribution
- DNS hostname and support enabled

## Usage

### Basic Usage

```hcl
module "vpc" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/vpc"
  
  prefix     = "myapp"
  cidr_block = "10.0.0.0/16"
}
```

### Advanced Usage

```hcl
module "vpc" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/vpc"
  
  prefix          = "production"
  cidr_block      = "172.16.0.0/16"
  subnet_size     = 2
  public_subnets  = ["172.16.1.0/24", "172.16.2.0/24"]
  private_subnets = ["172.16.101.0/24", "172.16.102.0/24"]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| prefix | Prefix for resource names | `string` | `"my"` | no |
| cidr_block | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| public_subnets | List of public subnet CIDR blocks | `list(string)` | `[]` | no |
| private_subnets | List of private subnet CIDR blocks | `list(string)` | `[]` | no |
| subnet_size | Number of subnets to create (public and private each) | `number` | `4` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_attribute | Object containing all VPC attributes |
| vpc_attribute.vpc_id | VPC ID |
| vpc_attribute.vpc_cidr_block | VPC CIDR block |
| vpc_attribute.public_subnet_ids | List of public subnet IDs |
| vpc_attribute.private_subnet_ids | List of private subnet IDs |
| vpc_attribute.public_subnet_cidr_blocks | List of public subnet CIDR blocks |
| vpc_attribute.private_subnet_cidr_blocks | List of private subnet CIDR blocks |
| vpc_attribute.security_group_id | Default security group ID |

## Security Group Rules

The module creates a security group with the following rules:

**Ingress:**

- SSH (port 22) from anywhere
- HTTP (port 80) from anywhere  
- HTTPS (port 443) from anywhere
- All traffic within VPC CIDR

**Egress:**

- All traffic to anywhere

## Subnet Auto-Generation

If `public_subnets` or `private_subnets` are not provided, the module automatically generates them:

- Public subnets: Uses `/24` subnets starting from the beginning of VPC CIDR
- Private subnets: Uses `/24` subnets starting from `.128.0/24` within VPC CIDR
- Subnets are distributed across available AZs

## Examples

### Accessing Outputs

```hcl
# Use VPC ID in other resources
resource "aws_instance" "example" {
  subnet_id              = module.vpc.vpc_attribute.public_subnet_ids[0]
  vpc_security_group_ids = [module.vpc.vpc_attribute.security_group_id]
  # ... other configuration
}

# Use in data sources
data "aws_vpc" "selected" {
  id = module.vpc.vpc_attribute.vpc_id
}
```

### Custom Subnet Configuration

```hcl
module "vpc" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/vpc"
  
  prefix          = "custom"
  cidr_block      = "192.168.0.0/16"
  subnet_size     = 3
  public_subnets  = [
    "192.168.1.0/24",
    "192.168.2.0/24", 
    "192.168.3.0/24"
  ]
  private_subnets = [
    "192.168.11.0/24",
    "192.168.12.0/24",
    "192.168.13.0/24"
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13 |
| aws | >= 6.0 |

## Notes

- Subnets are automatically distributed across available AZs
- Private subnets don't have internet gateway routes (add NAT gateway separately if needed)
- All resources are tagged with Environment = terraform.workspace
- DNS hostnames and support are enabled by default
