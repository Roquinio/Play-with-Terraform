# Credentials
variable "aws_access_key" {
  type      = string
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "eu-west-3"
}

# variable "aws_token" {
#   type      = string
#   sensitive = true
# }

variable "vpc_IP" {}

variable "subnet_IP" {
  type = string
}

variable "vpc_tags_name" {}

variable "subnet_tags_name" {}

variable "sg_name" {}

variable "bucket_name" {}

variable "ec2_ami" {}

variable "ec2_instance_type" {
  default = "t2.micro"
}

variable "ec2_name" {}

variable "ssh_key_name" {}

variable "public_key" {
  sensitive = true
}


# SNS 

# variable "topic_name" {
#   type = string
# }

# variable "topic_sub_dest" {
#   type = string
# }