# Free Tier IAM Module

Creates an IAM role and user with strict free tier limitations.

## Features
- Restricts to ap-southeast-1 region only
- EC2: Only t2.micro instances
- RDS: Only db.t2.micro instances  
- Auto Scaling Groups allowed
- Load Balancers allowed
- Resource isolation by user tags

## Usage
```hcl
module "free_tier_iam" {
  source = "./aws/iam"
  
  friend_username   = "john-doe"
  console_password  = "TempPassword123!"
}
```

## Deploy
```bash
terraform init
terraform apply -var="friend_username=your-friend-name" -var="console_password=TempPassword123!"
```

## Outputs
- Access Key ID and Secret Key
- Console login URL
- Role ARN for CLI access
- 3-hour session limit enforced

Your friend must assume the role to access AWS resources with these restrictions.