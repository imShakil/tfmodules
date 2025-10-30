output "role_arn" {
  description = "ARN of the free tier restricted role"
  value       = aws_iam_role.free_tier_role.arn
}

output "user_name" {
  description = "IAM username for your friend"
  value       = aws_iam_user.friend_user.name
}

output "access_key_id" {
  description = "Access Key ID for your friend"
  value       = aws_iam_access_key.friend_access_key.id
}

output "secret_access_key" {
  description = "Secret Access Key for your friend"
  value       = aws_iam_access_key.friend_access_key.secret
  sensitive   = true
}

output "console_login_url" {
  description = "AWS Console login URL"
  value       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}

output "assume_role_command" {
  description = "AWS CLI command to assume the role (3-hour session)"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.free_tier_role.arn} --role-session-name friend-session --duration-seconds 10800"
}

output "credentials_summary" {
  description = "Complete credentials summary for your friend"
  value = {
    username           = aws_iam_user.friend_user.name
    access_key_id      = aws_iam_access_key.friend_access_key.id
    secret_access_key  = aws_iam_access_key.friend_access_key.secret
    console_url        = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
    role_arn           = aws_iam_role.free_tier_role.arn
    session_duration   = "3 hours maximum"
    region_restriction = "ap-southeast-1 only"
  }
  sensitive = true
}