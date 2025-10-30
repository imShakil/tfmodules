data "aws_caller_identity" "current" {}

output "user_credentials" {
  description = "Complete credentials for the free tier user"
  value = {
    username          = aws_iam_user.freetier.name
    console_password  = aws_iam_user_login_profile.freetier.password
    access_key_id     = aws_iam_access_key.freetier.id
    secret_access_key = aws_iam_access_key.freetier.secret
    console_url       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
    expires_at        = var.access_expiry
  }
  sensitive = true
}