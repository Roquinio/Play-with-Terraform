# Create a S3 bucket
resource "aws_s3_bucket" "s3_Bucket" {
  bucket = var.bucket_name

}

resource "aws_s3_bucket_policy" "s3_policy_only_ec2" {
  bucket = var.bucket_name

  policy = <<EOF
  {
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "AllowAccessToEC2Instance",
          "Effect": "Deny",
          "Principal": "*",
          "Action": "s3:*",
          "Resource": "arn:aws:s3:::${var.bucket_name}/*",
          "Condition": {
              "NotIpAddress": {
                  "aws:SourceIp": "${aws_instance.ec2-5src4.private_ip}"
              }
          }
      }
  ]
}
EOF
}

# Create an EC2 instance
resource "aws_instance" "ec2-5src4" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.subnet_5src.id
  key_name                    = var.ssh_key_name
  associate_public_ip_address = true
  tags = {
    Name = var.ec2_name
  }
}


#Create Security group
resource "aws_security_group" "aws_sg_ingress_only" {
  name        = var.sg_name
  description = "Allow ssh"
  vpc_id      = aws_vpc.vpc_5src.id


  ingress {
    description      = "Allow ssh"
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

# Create a VPC
resource "aws_vpc" "vpc_5src" {
  cidr_block = var.vpc_IP

  tags = {
    Name = var.vpc_tags_name
  }
}

# Create a subnet
resource "aws_subnet" "subnet_5src" {
  vpc_id     = aws_vpc.vpc_5src.id
  cidr_block = var.subnet_IP

  tags = {
    Name = var.subnet_tags_name
  }
}

# Create key pair to ssh the EC2 instance
resource "aws_key_pair" "deploy_ssh_key" {
  key_name   = var.ssh_key_name
  public_key = var.public_key
}

# Attach the security group to the EC2 instance
resource "aws_network_interface_sg_attachment" "sg_attachment" {
  security_group_id    = aws_security_group.aws_sg_ingress_only.id
  network_interface_id = aws_instance.ec2-5src4.primary_network_interface_id
}

# Connect the internet gateway to the VPC
resource "aws_internet_gateway" "ig_5src4" {
  vpc_id = aws_vpc.vpc_5src.id
}

# Create route to the internet gateway
resource "aws_route_table" "rt_5src4" {
  vpc_id = aws_vpc.vpc_5src.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig_5src4.id
  }
}

# Associate the route table to the subnetwork
resource "aws_route_table_association" "rt_association" {
  subnet_id      = aws_subnet.subnet_5src.id
  route_table_id = aws_route_table.rt_5src4.id
}

# Create SNS for sending mail when EC2 instance is created
resource "aws_sns_topic" "topic_5src4" {
  name = var.topic_name
}

resource "aws_sns_topic_subscription" "topic_sub_5src4" {
  topic_arn = aws_sns_topic.topic_5src4.arn
  protocol  = "email"
  endpoint  = var.topic_sub_dest
}