variable "prefix" {
  default = "my"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "vpc_security_group_ids" {}
variable "subnet_id" {}
variable "ami_id" {}
variable "ssh_key_pair" {}

variable "user_data_path" {
  default = null
}

variable "tags" {
  default = null
}

variable "instance_number" {
  default     = 1
  type        = number
  description = "Number of instances to launch"
}
