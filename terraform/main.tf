# AWS Provider
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name        = "${var.project_name}-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.project_name}-public-subnet"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Public"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name        = "${var.project_name}-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group for EC2 instance
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for Odoo EC2 instance"
  vpc_id      = aws_vpc.main.id
  
  # SSH access (abierto desde cualquier IP)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # Odoo port (acceso directo abierto)
  ingress {
    description = "Odoo"
    from_port   = 8069
    to_port     = 8069
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.project_name}-ec2-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = var.public_key
  
  tags = {
    Name        = "${var.project_name}-key"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Spot Instance Request
resource "aws_spot_instance_request" "main" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.main.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  subnet_id              = aws_subnet.public.id
  
  spot_price                      = var.spot_price
  wait_for_fulfillment           = true
  spot_type                      = "one-time"
  instance_interruption_behavior = "terminate"
  
  # User data script
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    odoo_master_password = var.odoo_master_password
    postgres_password    = var.postgres_password
    domain_name         = var.domain_name
    letsencrypt_email   = var.letsencrypt_email
    efs_id              = var.existing_efs_id
    efs_mount_point     = var.efs_mount_point
  }))
  
  # EBS configuration
  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
    
    tags = {
      Name        = "${var.project_name}-root-volume"
      Environment = var.environment
      Project     = var.project_name
    }
  }
  
  tags = {
    Name        = "${var.project_name}-spot-instance"
    Environment = var.environment
    Project     = var.project_name
    Type        = "Spot"
  }
}

# Elastic IP (crear solo si no se proporciona uno existente)
resource "aws_eip" "main" {
  count  = var.existing_elastic_ip_id == "" ? 1 : 0
  domain = "vpc"
  
  tags = {
    Name        = "${var.project_name}-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Data source para Elastic IP existente
data "aws_eip" "existing" {
  count = var.existing_elastic_ip_id != "" ? 1 : 0
  id    = var.existing_elastic_ip_id
}

# Associate Elastic IP with the instance
resource "aws_eip_association" "main" {
  instance_id   = aws_spot_instance_request.main.spot_instance_id
  allocation_id = var.existing_elastic_ip_id != "" ? data.aws_eip.existing[0].id : aws_eip.main[0].id
  
  depends_on = [aws_spot_instance_request.main]
}

# EFS Configuration (opcional - usar EFS existente si se proporciona)
data "aws_efs_file_system" "existing" {
  count           = var.existing_efs_id != "" ? 1 : 0
  file_system_id  = var.existing_efs_id
}

# EFS Mount Target para el subnet público (solo si se usa EFS existente)
resource "aws_efs_mount_target" "main" {
  count           = var.existing_efs_id != "" ? 1 : 0
  file_system_id  = data.aws_efs_file_system.existing[0].id
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.efs[0].id]
}

# Security Group para EFS (solo si se usa EFS)
resource "aws_security_group" "efs" {
  count       = var.existing_efs_id != "" ? 1 : 0
  name        = "${var.project_name}-efs-sg"
  description = "Security group for EFS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-efs-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}
