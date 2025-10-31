# AWS EC2 Instance Terraform Module

This module creates AWS EC2 instances with SSH key pair management and configurable networking.

## Features

- Multiple EC2 instances with count support
- Automatic SSH key pair creation from public key file
- Configurable instance type and AMI
- VPC and security group integration
- Flexible subnet placement (public/private)

## Usage

### Basic Usage

```hcl
module "instance" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/instance"
  
  ami_id                 = "ami-12345678"
  subnet_id              = "subnet-12345"
  vpc_security_group_ids = ["sg-12345"]
  ssh_key_pair = {
    ssh_username = "mykey"
    ssh_key_path = "~/.ssh/id_rsa.pub"
  }
}
```

### Advanced Usage

```hcl
module "web_servers" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/instance"
  
  prefix         = "web"
  instance_type  = "t3.small"
  instance_number = 3
  ami_id         = "ami-0abcdef1234567890"
  subnet_id      = "subnet-12345"
  vpc_security_group_ids = ["sg-12345", "sg-67890"]
  ssh_key_pair = {
    ssh_username = "web-servers"
    ssh_key_path = "./keys/web-servers.pub"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| ami_id | AMI ID for the instance | `string` | n/a | yes |
| subnet_id | Subnet ID where instance will be launched | `string` | n/a | yes |
| vpc_security_group_ids | List of security group IDs | `list(string)` | n/a | yes |
| ssh_key_pair | SSH key configuration object | `object` | n/a | yes |
| prefix | Prefix for resource names | `string` | `"my"` | no |
| instance_type | EC2 instance type | `string` | `"t2.micro"` | no |
| instance_number | Number of instances to create | `number` | `1` | no |
| user_data_path | Path to user data script | `string` | `null` | no |
| tags | Additional tags for instances | `map(string)` | `null` | no |

### SSH Key Pair Object

The `ssh_key_pair` variable expects an object with:

```hcl
ssh_key_pair = {
  ssh_username = "key-name"        # Name for the AWS key pair
  ssh_key_path = "path/to/key.pub" # Path to public key file
}
```

## Outputs

| Name | Description |
|------|-------------|
| instance_attribute | Object containing all instance attributes |
| instance_attribute.id | List of instance IDs |
| instance_attribute.public_ip | List of public IP addresses |
| instance_attribute.private_ip | List of private IP addresses |
| instance_attribute.public_dns | List of public DNS names |
| instance_attribute.private_dns | List of private DNS names |
| instance_attribute.ssh_key_name | SSH key pair name |

## Examples

### Using Existing Infrastructure

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

module "web_instance" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/instance"
  
  prefix         = "web"
  ami_id         = data.aws_ami.ubuntu.id
  instance_type  = "t3.micro"
  subnet_id      = "subnet-12345"
  vpc_security_group_ids = ["sg-12345"]
  
  ssh_key_pair = {
    ssh_username = "web-server"
    ssh_key_path = "~/.ssh/id_rsa.pub"
  }
}
```

### Multiple Instances

```hcl
module "app_servers" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/instance"
  
  prefix          = "app"
  instance_number = 3
  instance_type   = "t3.small"
  ami_id          = "ami-0abcdef1234567890"
  subnet_id       = "subnet-private123"
  vpc_security_group_ids = ["sg-app123"]
  
  ssh_key_pair = {
    ssh_username = "app-cluster"
    ssh_key_path = "./keys/app-cluster.pub"
  }
}

# Access individual instances
output "first_instance_ip" {
  value = module.app_servers.instance_attribute.private_ip[0]
}
```

### Connecting to Instances

```bash
# SSH to first instance
ssh -i ~/.ssh/id_rsa ubuntu@${module.web_instance.instance_attribute.public_ip[0]}

# SSH to specific instance by index
ssh -i ~/.ssh/id_rsa ubuntu@${module.app_servers.instance_attribute.public_ip[2]}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 5.0 |

## Notes

- SSH public key file must exist at the specified path
- Instances in public subnets get public IPs automatically
- Ensure security groups allow SSH access (port 22)
- Instance names are auto-generated with index numbers
- Key pair is created once and reused for all instances in the module
