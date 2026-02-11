# Provider Configuration
# Specifies the AWS provider and region for Terraform to manage resources in.
provider "aws" {
  region = "us-east-1"
}

variable "key_name" {
    type = string
    sensitive = true
  }

terraform {
  backend "s3" {
    bucket = "cmn4315-terraform-bucket-1" # S3 bucket for state storage
    key = "prod/terraform.tfstate" # State file path in the bucket
    region = "us-east-1" # AWS region
    encrypt=true
  }
}

# EC2 Instance
# Launches an EC2 instance for WordPress and sets up user data.

# WordPress EC2 Instance
resource "aws_instance" "wordpress_ec2" {
  ami                    = data.aws_ami.amazon_linux_2023.id  # Use the AMI we filtered above
  instance_type          = "t2.micro"  # Free tier eligible instance type
  subnet_id              = aws_subnet.public_subnet.id  # Place in the public subnet
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]  # Attach the EC2 security group
  key_name               = var.key_name

  # TODO: Pass in the 4 variables to the user data script
  user_data = templatefile("wp_rds_install.sh", {
    db_name = "wordpressdb"
    db_user = var.db_username
    db_password = var.db_password
    db_endpoint = aws_db_instance.wordpress_db.endpoint
  })

  tags = {
    Name = "WordPress EC2 Instance"
  }
}

variable "db_username" {
    type = string
    sensitive = true
  }

variable "db_password" {
    type = string
    sensitive = true
  }

# RDS Database
# Set up a MySQL RDS instance for WordPress.

# RDS Instance
resource "aws_db_instance" "wordpress_db" {
  identifier           = "wordpress-db"  # Unique identifier for the RDS instance
  allocated_storage    = 20  # 20GB of storage
  storage_type         = "gp2"  # General Purpose SSD
  engine               = "mysql"  # MySQL database engine
  engine_version       = "8.0"  # MySQL version 8.0
  instance_class       = "db.t3.micro"  # Free tier eligible instance type
  db_name              = "wordpressdb"  # Name of the WordPress database
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"  # Default parameter group for MySQL 8.0
  skip_final_snapshot  = true  # Skip final snapshot when destroying the database
  vpc_security_group_ids = [aws_security_group.rds_sg.id]  # Attach the RDS security group
  db_subnet_group_name = aws_db_subnet_group.wordpress_db_subnet_group.name  # Use the created subnet group
}

