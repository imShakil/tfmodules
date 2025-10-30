variable "prefix" {
  default = "my"
}

variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(any)
  default = []
}

variable "private_subnets" {
  type    = list(any)
  default = []
}

variable "subnet_size" {
  type        = number
  description = "Number of subnets to create (public and private each)"
  default     = 4
}
