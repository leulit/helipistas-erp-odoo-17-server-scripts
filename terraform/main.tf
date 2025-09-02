# main.tf - Configuración simplificada para Helipistas Odoo 17

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# DATA SOURCES
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
}

# USAR VPC EXISTENTE
data "aws_vpc" "main" {
  id = "vpc-92d074f6" # VPC WEBS existente
}

data "aws_subnet" "public" {
  vpc_id            = data.aws_vpc.main.id
  availability_zone = "eu-west-1b"
  filter {
    name   = "subnet-id"
    values = ["subnet-c362e2a7"] # Subnet existente en eu-west-1b
  }
}

# SECURITY GROUP SIMPLE
resource "aws_security_group" "main" {
  name        = "${var.resource_prefix}-SG"
  description = "Security group for Helipistas Odoo"
  vpc_id      = data.aws_vpc.main.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Odoo
  ingress {
    from_port   = 8069
    to_port     = 8069
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # EFS
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    self      = true
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.resource_prefix}-SG"
  }
}

# INSTANCIA EC2 REGULAR (NO SPOT PARA SIMPLICIDAD)
resource "aws_instance" "main" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.main.id]
  subnet_id              = data.aws_subnet.public.id
  availability_zone      = "eu-west-1b"

  root_block_device {
    volume_type = "gp3"
    volume_size = var.root_volume_size
    encrypted   = true
  }

  # Forzar recreación SIEMPRE en cada apply
  lifecycle {
    create_before_destroy = false
  }

  # Este campo cambia en cada apply forzando recreación
  user_data_base64 = base64encode("${templatefile("${path.module}/user_data_simple.sh", {
    POSTGRES_PASSWORD    = var.postgres_password
    ODOO_MASTER_PASSWORD = var.odoo_master_password
    EFS_ID               = var.existing_efs_id
    ELASTIC_IP_ID        = var.existing_elastic_ip_id
    DOMAIN_NAME          = var.domain_name
  })}-${timestamp()}")

  tags = {
    Name = "${var.resource_prefix}-INSTANCE"
  }
}

# ASOCIAR ELASTIC IP
resource "aws_eip_association" "main" {
  instance_id   = aws_instance.main.id
  allocation_id = var.existing_elastic_ip_id

  depends_on = [aws_instance.main]
}
