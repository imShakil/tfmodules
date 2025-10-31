# AWS RDS Terraform Module

This module creates an AWS RDS instance with a DB subnet group for secure database deployment in private subnets.

## Features

- RDS instance with configurable engine and version
- DB subnet group for multi-AZ deployment
- Configurable storage and instance class
- Security group integration
- Skip final snapshot option for development environments

## Usage

### Basic Usage

```hcl
module "rds" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/rds"
  
  rds_name            = "myapp"
  rds_admin           = "admin"
  rds_admin_password  = "securepassword123"
  private_subnets     = ["subnet-12345", "subnet-67890"]
  security_group_ids  = ["sg-12345"]
}
```

### Advanced Usage

```hcl
module "rds" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/rds"
  
  prefix              = "production"
  rds_name            = "proddb"
  rds_admin           = "dbadmin"
  rds_admin_password  = "VerySecurePassword123!"
  private_subnets     = ["subnet-abc123", "subnet-def456"]
  security_group_ids  = ["sg-abc123"]
  
  engine              = "postgres"
  engine_version      = "15.4"
  instance_class      = "db.t3.small"
  storage_size        = 100
  skip_final_snapshot = false
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| rds_name | Database name | `string` | n/a | yes |
| rds_admin | Database admin username | `string` | n/a | yes |
| rds_admin_password | Database admin password | `string` | n/a | yes |
| private_subnets | List of private subnet IDs | `list(string)` | n/a | yes |
| security_group_ids | List of security group IDs | `list(string)` | n/a | yes |
| prefix | Prefix for resource names | `string` | `"myrds"` | no |
| engine | Database engine | `string` | `"mysql"` | no |
| engine_version | Database engine version | `string` | `"8.0"` | no |
| instance_class | RDS instance class | `string` | `"db.t4g.micro"` | no |
| storage_size | Allocated storage in GB | `number` | `20` | no |
| skip_final_snapshot | Skip final snapshot on deletion | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| rds_info | Object containing all RDS attributes |
| rds_info.id | RDS instance ID |
| rds_info.hostname | RDS instance hostname |
| rds_info.db_name | Database name |
| rds_info.username | Database username |
| rds_info.endpoint | RDS instance endpoint |
| rds_info.engine | Database engine |
| rds_info.instance_class | RDS instance class |
| rds_info.status | RDS instance status |

## Examples

### Using Existing Infrastructure

```hcl
module "rds" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/rds"
  
  rds_name            = "appdb"
  rds_admin           = "admin"
  rds_admin_password  = var.db_password
  private_subnets     = ["subnet-12345", "subnet-67890"]
  security_group_ids  = ["sg-12345"]
}
```

### PostgreSQL Configuration

```hcl
module "postgres_rds" {
  source = "git::https://github.com/imShakil/tfmodules.git//aws/rds"
  
  prefix              = "postgres"
  rds_name            = "postgres"
  rds_admin           = "postgres"
  rds_admin_password  = "SecurePostgresPass123!"
  private_subnets     = ["subnet-private1-id", "subnet-private2-id"]
  security_group_ids  = ["sg-database-id"]
  
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t4g.micro"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.13 |
| aws | >= 6.0 |

## Notes

- Database is deployed in private subnets for security
- Ensure security groups allow database port access (3306 for MySQL, 5432 for PostgreSQL)
- Use strong passwords and consider AWS Secrets Manager for production
- Set `skip_final_snapshot = false` for production databases
- DB subnet group requires at least 2 subnets in different AZs
