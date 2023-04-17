# Pre-reqs:
# Make sure your ssm parameter store is configured with db password and is encrypted
# IAM Admin access for api user in AWS so that Terrafrom has no issue accessing and deploying resources

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider in Canada region ca-central-1 with personal aws profile
provider "aws" {
  profile = "personal"
  region = "ca-central-1"
}

# Create a VPC with CIDR block 10.0.0.0/16
resource "aws_vpc" "vpc_skip" {
  cidr_block = "10.10.0.0/16"
}

# Creating public subnet for web and private subnet for database
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "public_subnet_skip" {
  vpc_id     = aws_vpc.vpc_skip.id
  cidr_block = "10.10.1.0/24"

  tags = {
    Name = "Public_subnet"
  }
}
resource "aws_subnet" "private_subnet_skip" {
  vpc_id     = aws_vpc.vpc_skip.id
  cidr_block = "10.10.2.0/24"

  tags = {
    Name = "Private_subnet"
  }
}

# Creating internet gateway to access resources over the internet to the subnet
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "gw_skip" {
  vpc_id = aws_vpc.vpc_skip.id
}

# Creating AWS route_table with default route to internet 
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "public_rt_skip" {
  vpc_id = aws_vpc.vpc_skip.id
  # 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_skip.id
  }
}
resource "aws_route_table" "private_rt_skip" {
  vpc_id = aws_vpc.vpc_skip.id
  # based on my understanding the Database should not be exposed to public internet so table does not allow any route
}

# Associating respective route table to public and private subnets
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "public_rt_association_skip" {
  subnet_id      = aws_subnet.public_subnet_skip.id
  route_table_id = aws_route_table.public_rt_skip.id
}
resource "aws_route_table_association" "private_rt_association_skip" {
  subnet_id      = aws_subnet.private_subnet_skip.id
  route_table_id = aws_route_table.private_rt_skip.id
}

# Creating AWS sg for ssh, http conections to EC2 instance via VPN IP address range and allow all outbound traffice
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "ssh_http_sg_skip" {
  name        = "ssh_http_via_vpn"
  description = "Allow ssh and http inbound traffic from VPN only"
  vpc_id      = aws_vpc.vpc_skip.id

  ingress {
    description      = "ssh to instance"
    from_port        = 22
    to_port          = 22
    protocol         = "ssh"
    cidr_blocks      = ["172.124.0.0/16"] # VPN IP
  }

  ingress {
    description      = "http to web instance"
    from_port        = 80
    to_port          = 80
    protocol         = "http"
    cidr_blocks      = ["172.124.0.0/16"] # VPN IP
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}

# Creating AWS sg for RDS instance to communicate with EC2 with no outside traffic allowed
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# Ref: https://dev.mysql.com/doc/mysql-port-reference/en/mysql-ports-reference-tables.html#:~:text=Port%203306%20is%20the%20default,such%20as%20mysqldump%20and%20mysqlpump.
resource "aws_security_group" "rds_sg_skip" {
  name        = "allow_ec2_port"
  description = "Allow EC2 instance inbound TCP traffic via default port 3306 for MySQL"
  vpc_id      = aws_vpc.vpc_skip.id

  ingress {
    description      = "ssh to instance"
    from_port        = "3306" # Port 3306 is the default port for MySQL protocol
    to_port          = "3306" 
    protocol         = "tcp"
    security_groups  = [aws_security_group.ssh_http_sg_skip] # Source access restricted to EC2 instance sg
  }

}

# Creating db subnet group
# DB instance will be created in the VPC associated with the DB subnet group. If unspecified, will be created in the default VPC.
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group
resource "aws_db_subnet_group" "rds_subnet_group_skip" {
  name       = "db_group"
  subnet_ids = [aws_subnet.private_subnet_skip.id]
}

# Creating RDS instance and fetcting encrypted password secret from parameter store
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter
# Ref: https://developer.hashicorp.com/terraform/tutorials/aws/aws-rds?utm_medium=WEB_IO&in=terraform%2Faws&utm_offer=ARTICLE_PAGE&utm_source=WEBSITE&utm_content=DOCS
resource "aws_db_instance" "mysql_rds_skip" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.16"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "skip"
  password             = data.aws_ssm_parameter.db_pass_skip.value # pull pass from parameter store
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group_skip.name
  parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.rds_sg_skip.id]
  skip_final_snapshot    = true 
}

# Following can be used to create ssm parameter resource using some sort of variable file. 
# I have assumed the secrets are created manually inside aws ssm parameter store due to security reason
/*
resource "aws_ssm_parameter" "secret" {
  name        = "/skip/pass"
  description = "Encrpted Password to access db"
  type        = "SecureString"
  value       = var.database_master_password
}
*/
# Obtaining password from ssm parameter store
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter
data "aws_ssm_parameter" "db_pass_skip" { 
  name = "/skip/pass" # Should be manually configured before deploying the infra
  with_decryption = true # Decrypt when pulled
}

# Create your ssh key pair:
/*
This can be done through the console in EC2 -> key-pairs 
or through your mac using ssh-keygen command
In my case, ssh key pair is already present in EC2 console so will pull public key from there
*/
# Obtaining exisitng ssh public key from EC2 key pairs to configure ssh public key on the instance
data "aws_key_pair" "ec2_access_key_skip" {
  key_name   = "user-access-key"
  include_public_key = true
}

# Obtaining latest ami of AL2 with x86_64 arch
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
# Ref: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-images.html
# Ref: https://stackoverflow.com/questions/67648404/terraform-aws-ami-datasource-filter-problem
data "aws_ami" "al2_latest_ami_skip" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name = "owner-alias"
    values = "amazon"
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

 filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name = "root-device-type"
    values= "ebs" 
  }
}


# Creating AWS EC2 instance and intializing it
# Public keys for dev can be configured here and database setup can be automated in user_data
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
resource "aws_instance" "web_instance_skip" {
  ami           = data.aws_ami.al2_latest_ami_skip
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet_skip.id
  key_name = data.aws_key_pair.ec2_access_key_skip.key_name
  vpc_security_group_ids = [aws_security_group.ssh_http_sg_skip.id]
  user_data = <<-EOF
  #!/bin/bash
  echo "Setting up web server"
  sudo yum update -y
  sudo yum install apache2 -y
  sudo systemctl start apache2
  sudo bash -c 'echo skip web server > /var/www/html/index.html'
  echo "Setting update RDS MySQL database"
  sudo yum install mysql -y
  EOF
}

# Creating elastice IP and attaching to EC2 instance. 
resource "aws_eip" "eip_ec2_skip" {
  instance = aws_instance.web_instance_skip.id
  vpc      = true
}
