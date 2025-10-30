variable "rds_name" {}
variable "rds_admin" {}
variable "rds_admin_password" {}
variable "private_subnets" {}
variable "security_group_ids" {}

variable "storage_size" {
  default = 20
}

variable "prefix" {
  default = "myrds"
}

variable "engine" {
  default = "mysql"
}

variable "engine_version" {
  default = "8.0"
}

variable "instance_class" {
  default = "db.t4g.micro"
}

variable "skip_final_snapshot" {
  default = true
  type    = bool
}
