# Generate SSH Key
resource "tls_private_key" "tnc_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Store SSH Key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "tnc_ssh_key" {
  name = "${var.key_name}_secret_new"
}

resource "aws_secretsmanager_secret_version" "tnc_ssh_key_version" {
  secret_id     = aws_secretsmanager_secret.tnc_ssh_key.id
  secret_string = tls_private_key.tnc_key.private_key_pem
}

# Create EC2 Key Pair
resource "aws_key_pair" "tnc_keypair" {
  key_name   = var.key_name
  public_key = tls_private_key.tnc_key.public_key_openssh
}

# VPC
resource "aws_vpc" "tnc_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "tnc_vpc"
  }
}

# Subnets
resource "aws_subnet" "tnc_subnet_1" {
  vpc_id            = aws_vpc.tnc_vpc.id
  cidr_block        = var.public_subnet_cidr_1
  availability_zone = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "tnc_subnet_1"
  }
}

resource "aws_subnet" "tnc_subnet_2" {
  vpc_id            = aws_vpc.tnc_vpc.id
  cidr_block        = var.public_subnet_cidr_2
  availability_zone = "us-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "tnc_subnet_2"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "tnc_igw" {
  vpc_id = aws_vpc.tnc_vpc.id
  tags = {
    Name = "tnc_igw"
  }
}

# Create Route Table
resource "aws_route_table" "tnc_route_table" {
  vpc_id = aws_vpc.tnc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tnc_igw.id
  }

  tags = {
    Name = "tnc_route_table"
  }
}

# Associate Route Table with Subnet 1
resource "aws_route_table_association" "tnc_rta_1" {
  subnet_id      = aws_subnet.tnc_subnet_1.id
  route_table_id = aws_route_table.tnc_route_table.id
}

# Associate Route Table with Subnet 2
resource "aws_route_table_association" "tnc_rta_2" {
  subnet_id      = aws_subnet.tnc_subnet_2.id
  route_table_id = aws_route_table.tnc_route_table.id
}

# Security Group
resource "aws_security_group" "tnc_sg" {
  vpc_id = aws_vpc.tnc_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tnc_sg"
  }
}



# Create EC2 Instance
resource "aws_instance" "tnc_instance" {
  ami           = "ami-06068bc7800ac1a83" #Replace with preferred option
  instance_type = var.instance_type
  subnet_id     = aws_subnet.tnc_subnet_2.id
  key_name      =  aws_key_pair.tnc_keypair.key_name
  security_groups = [aws_security_group.tnc_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y apache2
              echo 'Hello, TNC!' > /var/www/html/index.html
              systemctl start apache2
              systemctl enable apache2
              EOF

  tags = {
    Name = "tnc_instance"
  }
}
