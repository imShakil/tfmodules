variable "prefix" {
  default = "my"
}

variable "region" {
  default = "ap-southeast-1"
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-southeast-1a", "ap-southeast-1b"]

}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.16.0/24"]
}

variable "allow_publicIP" {
  default = true
  type    = bool
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.128.0/24", "10.0.144.0/24"]
}
