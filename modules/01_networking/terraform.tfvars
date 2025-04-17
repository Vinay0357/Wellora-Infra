#################################################################
# Networking
#################################################################

aws_region               = "ap-southeast-2"
project_name             = "wellora"
environment              = "prod"
vpc_cidr                 = "10.98.0.0/16"
number_of_azs_to_use     = 3

public_subnet_cidrs      = ["10.98.1.0/24", "10.98.2.0/24", "10.98.3.0/24"]
private_app_subnet_cidrs = ["10.98.10.0/23", "10.98.12.0/23", "10.98.14.0/23"]
private_db_subnet_cidrs  = ["10.98.20.0/24", "10.98.21.0/24", "10.98.22.0/24"]

enable_nat_gateway       = true
single_nat_gateway       = false
enable_dns_hostnames     = true
enable_dns_support       = true

common_tags = {
  "Owner"      = "Minfy"
  "CostCenter" = "Wellora"
}
