# S3 Bucket
variable "bucket_name" {
  type = string
}

variable "ec2_ami" {
  type = string
}
variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "ec2_name" {
  type = string
}

# Security Group
variable "sg_name" {
  type = string
}


# VPC
variable "vpc_IP" {
}

variable "vpc_tags_name" {
  type = string
}

# Subnet

variable "subnet_tags_name" {
  type = string
}

variable "subnet_IP" {
  type = string
}

# Key Pair
variable "ssh_key_name" {
  type = string
}

variable "public_key" {
  type = string
}

# SNS 

variable "topic_name" {
  type = string
}

variable "topic_sub_dest" {
  type = string
}
