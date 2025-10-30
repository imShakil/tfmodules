resource "random_string" "test" {
  length = 5
  lower  = true
}

resource "aws_iam_user" "freetier" {
  name = "${var.username}_${random_string.test.result}"
  path = "/freetier/"
  tags = {
    Type = "Free Tier User"
  }
}

resource "aws_iam_access_key" "freetier" {
  user = aws_iam_user.freetier.name
}

resource "aws_iam_user_login_profile" "freetier" {
  user                    = aws_iam_user.freetier.name
  password_reset_required = false
  password_length         = 8
}

resource "aws_iam_user_group_membership" "freetiergroup" {
  user = aws_iam_user.freetier.name
  groups = [
    "FreeTierGroup"
  ]
}

resource "aws_iam_user_policy" "time_based_access" {
  count = var.access_expiry != "" ? 1 : 0
  name  = "TimeBasedAccess"
  user  = aws_iam_user.freetier.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          DateGreaterThan = {
            "aws:CurrentTime" = var.access_expiry
          }
        }
      }
    ]
  })
}

resource "null_resource" "cleanup_resources" {
  triggers = {
    user_name = aws_iam_user.freetier.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      USER=${aws_iam_user.freetier.name}
      
      # Delete Auto Scaling Groups
      aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(Tags[?Key=='Owner'].Value, '$USER')].AutoScalingGroupName" --output text | xargs -I {} aws autoscaling delete-auto-scaling-group --auto-scaling-group-name {} --force-delete || true
      
      # Delete Load Balancers (ALB/NLB)
      aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(Tags[?Key=='Owner'].Value, '$USER')].LoadBalancerArn" --output text | xargs -I {} aws elbv2 delete-load-balancer --load-balancer-arn {} || true
      
      # Delete Classic Load Balancers
      aws elb describe-load-balancers --query "LoadBalancerDescriptions[?contains(Tags[?Key=='Owner'].Value, '$USER')].LoadBalancerName" --output text | xargs -I {} aws elb delete-load-balancer --load-balancer-name {} || true
      
      # Delete RDS instances
      aws rds describe-db-instances --query "DBInstances[?contains(TagList[?Key=='Owner'].Value, '$USER')].DBInstanceIdentifier" --output text | xargs -I {} aws rds delete-db-instance --db-instance-identifier {} --skip-final-snapshot --delete-automated-backups || true
      
      # Delete EC2 instances
      aws ec2 terminate-instances --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Owner,Values=$USER" --query 'Reservations[].Instances[].InstanceId' --output text) || true
      
      # Wait for instances to terminate
      sleep 30
      
      # Delete Security Groups
      aws ec2 describe-security-groups --filters "Name=tag:Owner,Values=$USER" --query 'SecurityGroups[].GroupId' --output text | xargs -I {} aws ec2 delete-security-group --group-id {} || true
      
      # Delete Subnets
      aws ec2 describe-subnets --filters "Name=tag:Owner,Values=$USER" --query 'Subnets[].SubnetId' --output text | xargs -I {} aws ec2 delete-subnet --subnet-id {} || true
      
      # Delete Internet Gateways
      aws ec2 describe-internet-gateways --filters "Name=tag:Owner,Values=$USER" --query 'InternetGateways[].InternetGatewayId' --output text | xargs -I {} sh -c 'aws ec2 detach-internet-gateway --internet-gateway-id {} --vpc-id $(aws ec2 describe-internet-gateways --internet-gateway-ids {} --query "InternetGateways[0].Attachments[0].VpcId" --output text) && aws ec2 delete-internet-gateway --internet-gateway-id {}' || true
      
      # Delete VPCs
      aws ec2 describe-vpcs --filters "Name=tag:Owner,Values=$USER" --query 'Vpcs[].VpcId' --output text | xargs -I {} aws ec2 delete-vpc --vpc-id {} || true
      
      # Delete S3 buckets
      aws s3api list-buckets --query "Buckets[?contains(Name, '$USER')].Name" --output text | xargs -I {} aws s3 rb s3://{} --force || true
    EOT
  }
}