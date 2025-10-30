data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "free_tier_policy" {
  name = "FreeTierRestrictedPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:CreateTags",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeRouteTables",
          "ec2:DescribeAvailabilityZones"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "ap-southeast-1"
            "ec2:InstanceType"    = "t2.micro"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "ap-southeast-1"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "rds:CreateDBInstance",
          "rds:DeleteDBInstance",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:StartDBInstance",
          "rds:StopDBInstance"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion"   = "ap-southeast-1"
            "rds:db-instance-class" = "db.t2.micro"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "ap-southeast-1"
          }
        }
      },
      {
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "ec2:InstanceType" = "t2.micro"
          }
        }
      },
      {
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = "ap-southeast-1"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "free_tier_role" {
  name                 = "FreeTierUserRole"
  max_session_duration = 10800 # 3 hours

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "free_tier_attachment" {
  role       = aws_iam_role.free_tier_role.name
  policy_arn = aws_iam_policy.free_tier_policy.arn
}

resource "aws_iam_user" "friend_user" {
  name = var.friend_username
}

resource "aws_iam_user_policy" "assume_role_policy" {
  name = "AssumeFreeTierRole"
  user = aws_iam_user.friend_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.free_tier_role.arn

      }
    ]
  })
}

resource "aws_iam_access_key" "friend_access_key" {
  user = aws_iam_user.friend_user.name
}

resource "aws_iam_user_login_profile" "friend_console" {
  user                    = aws_iam_user.friend_user.name
  password_reset_required = false
  password_length         = 12
}

# Add tagging requirement to the policy
resource "aws_iam_policy" "tagging_policy" {
  name = "RequireTaggingPolicy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = [
          "ec2:RunInstances",
          "rds:CreateDBInstance",
          "elasticloadbalancing:CreateLoadBalancer"
        ]
        Resource = "*"
        Condition = {
          "Null" = {
            "aws:RequestedTag/CreatedBy" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "tagging_attachment" {
  role       = aws_iam_role.free_tier_role.name
  policy_arn = aws_iam_policy.tagging_policy.arn
}