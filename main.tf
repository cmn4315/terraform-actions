# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"  # Set AWS region to US East 1 (N. Virginia)
}

# Local variables block for configuration values
locals {
    aws_key = "AWS_KEY_2"   # SSH key pair name for EC2 instance access
}

terraform {
  backend "s3" {
    bucket = "cmn4315-terraform-bucket-1" # S3 bucket for state storage
    key = "prod/terraform.tfstate" # State file path in the bucket
    region = "us-east-1" # AWS region
    encrypt = true
  }
}

# Allow HTTP traffic from the internet
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to public
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance resource definition
resource "aws_instance" "my_server" {
   ami           = data.aws_ami.amazonlinux.id  # Use the AMI ID from the data source
   instance_type = var.instance_type            # Use the instance type from variables
   key_name      = "${local.aws_key}"          # Specify the SSH key pair name
   user_data = file("./wp_install.sh")

   vpc_security_group_ids = [aws_security_group.allow_http.id]
  
   # Add tags to the EC2 instance for identification
   tags = {
     Name = "my ec2"
   }                  
}
