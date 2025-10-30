variable "friend_username" {
  description = "Username for your friend's IAM user"
  type        = string
  default     = "freetierUser"
}

variable "console_password" {
  description = "Initial console password for your friend"
  type        = string
  sensitive   = true
  default     = "abCD#1234"
}

variable "max_ec2_instances" {
  description = "Maximum number of EC2 instances allowed"
  type        = number
  default     = 3
}

variable "max_rds_instances" {
  description = "Maximum number of RDS instances allowed"
  type        = number
  default     = 1
}

variable "max_load_balancers" {
  description = "Maximum number of load balancers allowed"
  type        = number
  default     = 1
}