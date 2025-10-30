provider "aws" {
  region = "ap-southeast-1"
}

#-------- Test AWS VPC ---------

# module "awsVPC" {
#   source             = "./vpc"
#   region             = var.region
#   cidr_block         = var.cidr_block
#   prefix             = var.prefix
#   availability_zones = var.availability_zones

# }

# module "ec2" {
#   source = "./compute"
#   prefix = var.prefix
#   subnet_id = module.awsVPC.public_subnets

# }


module "iam_free_temp_user" {
  source = "./iam/free_temp_user"

}
