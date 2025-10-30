# Lambda function to enforce resource limits
resource "aws_lambda_function" "resource_limiter" {
  filename      = "resource_limiter.zip"
  function_name = "FreeTierResourceLimiter"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"
  timeout       = 60

  depends_on = [data.archive_file.lambda_zip]
}

# Lambda execution role
resource "aws_iam_role" "lambda_role" {
  name = "FreeTierLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "FreeTierLambdaPolicy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ec2:DescribeInstances",
          "ec2:TerminateInstances",
          "rds:DescribeDBInstances",
          "rds:DeleteDBInstance",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DeleteLoadBalancer"
        ]
        Resource = "*"
      }
    ]
  })
}

# EventBridge rule to trigger on resource creation
resource "aws_cloudwatch_event_rule" "resource_creation" {
  name = "FreeTierResourceCreation"

  event_pattern = jsonencode({
    source = ["aws.ec2", "aws.rds", "aws.elasticloadbalancing"]
    detail-type = [
      "EC2 Instance State-change Notification",
      "RDS DB Instance Event",
      "ELB Application Load Balancer Event"
    ]
    detail = {
      state = ["running", "available", "active"]
    }
  })
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.resource_creation.name
  target_id = "FreeTierLambdaTarget"
  arn       = aws_lambda_function.resource_limiter.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.resource_limiter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.resource_creation.arn
}

# Lambda function code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "resource_limiter.zip"
  source {
    content  = <<EOF
import boto3
import json

def handler(event, context):
    ec2 = boto3.client('ec2', region_name='ap-southeast-1')
    rds = boto3.client('rds', region_name='ap-southeast-1')
    elb = boto3.client('elbv2', region_name='ap-southeast-1')
    
    # Resource limits
    MAX_EC2 = 3
    MAX_RDS = 1
    MAX_LB = 1
    
    try:
        # Check EC2 instances
        ec2_response = ec2.describe_instances(
            Filters=[
                {'Name': 'instance-state-name', 'Values': ['running', 'pending']},
                {'Name': 'tag:CreatedBy', 'Values': ['${var.friend_username}']}
            ]
        )
        
        running_instances = []
        for reservation in ec2_response['Reservations']:
            for instance in reservation['Instances']:
                running_instances.append(instance['InstanceId'])
        
        if len(running_instances) > MAX_EC2:
            # Terminate excess instances
            excess_instances = running_instances[MAX_EC2:]
            ec2.terminate_instances(InstanceIds=excess_instances)
            print(f"Terminated excess EC2 instances: {excess_instances}")
        
        # Check RDS instances
        rds_response = rds.describe_db_instances()
        rds_instances = [db['DBInstanceIdentifier'] for db in rds_response['DBInstances'] 
                        if db['DBInstanceStatus'] in ['available', 'creating']]
        
        if len(rds_instances) > MAX_RDS:
            excess_rds = rds_instances[MAX_RDS:]
            for db_id in excess_rds:
                rds.delete_db_instance(
                    DBInstanceIdentifier=db_id,
                    SkipFinalSnapshot=True
                )
            print(f"Deleted excess RDS instances: {excess_rds}")
        
        # Check Load Balancers
        lb_response = elb.describe_load_balancers()
        load_balancers = [lb['LoadBalancerArn'] for lb in lb_response['LoadBalancers']]
        
        if len(load_balancers) > MAX_LB:
            excess_lbs = load_balancers[MAX_LB:]
            for lb_arn in excess_lbs:
                elb.delete_load_balancer(LoadBalancerArn=lb_arn)
            print(f"Deleted excess Load Balancers: {excess_lbs}")
        
        return {
            'statusCode': 200,
            'body': json.dumps('Resource limits enforced successfully')
        }
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error enforcing limits: {str(e)}')
        }
EOF
    filename = "index.py"
  }
}