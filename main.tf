terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
  token      = var.aws_token
}

module "tp_grp28" {
  source = "./modules/infra"

  # VPC
  vpc_IP        = var.vpc_IP
  vpc_tags_name = var.vpc_tags_name

  # Subnet
  subnet_tags_name = var.subnet_tags_name
  subnet_IP        = var.subnet_IP

  # Security Group
  sg_name = var.sg_name

  # Bucket
  bucket_name = var.bucket_name

  # EC2
  ec2_ami           = var.ec2_ami
  ec2_instance_type = var.ec2_instance_type
  ec2_name          = var.ec2_name

  # SSH Key pair
  ssh_key_name = var.ssh_key_name
  public_key   = var.public_key

  # SNS
  topic_name     = var.topic_name
  topic_sub_dest = var.topic_sub_dest

}

output "myip" {
  value       = module.tp_grp28.myip
  description = "Output the public ip of the instance"
}