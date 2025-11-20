# ============================================
# SPOT INSTANCE DEPLOYMENT - ODOO 17 ERP
# ============================================
# Deployment con AWS Spot Instances para desarrollo/staging
# Incluye auto-recovery automático tras terminación de AWS
# Costo: ~70% más barato que On-Demand (~$9/mes vs $30/mes)
# ============================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================
# DATA SOURCES - Recursos existentes
# ============================================

# AMI de Amazon Linux 2 (más reciente)
data "aws_ami" "amazon_linux_2" {
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

# VPC existente
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Subnet existente
data "aws_subnet" "existing" {
  id = var.subnet_id
}

# ============================================
# SECURITY GROUP - Firewall
# ============================================

resource "aws_security_group" "odoo_spot_sg" {
  name        = "odoo-spot-security-group"
  description = "Security group for Odoo Spot Instance"
  vpc_id      = var.vpc_id

  # SSH (solo desde IP específica)
  ingress {
    description = "SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP (redirige a HTTPS)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NFS para EFS
  ingress {
    description = "NFS for EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.existing.cidr_block]
  }

  # Egress: Permitir todo el tráfico saliente
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "odoo-spot-sg"
    Environment = var.environment
    Project     = "Helipistas-Odoo-17"
  }
}

# ============================================
# EBS VOLUME (Opcional) - Almacenamiento adicional
# ============================================

resource "aws_ebs_volume" "spot_data" {
  count             = var.ebs_volume_size > 0 ? 1 : 0
  availability_zone = data.aws_subnet.existing.availability_zone
  size              = var.ebs_volume_size
  type              = var.ebs_volume_type
  encrypted         = true

  tags = {
    Name        = "odoo-spot-data-volume"
    Environment = var.environment
    Project     = "Helipistas-Odoo-17"
  }
}

# ============================================
# IAM ROLE - Permisos para la instancia
# ============================================

# Rol IAM para la instancia EC2
resource "aws_iam_role" "spot_instance_role" {
  name = "odoo-spot-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "odoo-spot-instance-role"
    Environment = var.environment
    Project     = "Helipistas-Odoo-17"
  }
}

# Política para acceso a EFS
resource "aws_iam_role_policy" "efs_access" {
  name = "efs-access-policy"
  role = aws_iam_role.spot_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:DescribeFileSystems"
        ]
        Resource = "arn:aws:elasticfilesystem:${var.aws_region}:*:file-system/${var.efs_id}"
      }
    ]
  })
}

# Política para CloudWatch Logs (opcional)
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "cloudwatch-logs-policy"
  role = aws_iam_role.spot_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/ec2/odoo-spot:*"
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "spot_instance_profile" {
  name = "odoo-spot-instance-profile"
  role = aws_iam_role.spot_instance_role.name

  tags = {
    Name        = "odoo-spot-instance-profile"
    Environment = var.environment
    Project     = "Helipistas-Odoo-17"
  }
}

# ============================================
# SPOT INSTANCE REQUEST - Servidor principal  
# ============================================
# Opción simple: Solo un tipo de instancia
# Para múltiples tipos usar Fleet (ver abajo)

resource "aws_spot_instance_request" "odoo_spot" {
  count = var.use_fleet_instead_of_spot_request ? 0 : 1

  # CRÍTICO: persistent = auto-recovery tras terminación
  spot_type                      = "persistent"
  instance_interruption_behavior = "terminate"
  wait_for_fulfillment           = true
  valid_until                    = var.spot_valid_until

  # Precio máximo (null = precio on-demand, siempre disponible)
  spot_price = var.spot_max_price

  # Configuración de instancia
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type_primary
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.odoo_spot_sg.id]
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.spot_instance_profile.name

  # EBS root volume
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # User data: Bootstrap mínimo
  user_data = templatefile("${path.module}/user_data_spot.sh", {
    efs_id            = var.efs_id
    efs_mount_point   = var.efs_mount_point
    ebs_device        = var.ebs_volume_size > 0 ? "/dev/xvdf" : ""
    ebs_mount_point   = var.ebs_mount_point
    postgres_password = var.postgres_password
    github_repo       = var.github_repo
    github_branch     = var.github_branch
  })

  tags = {
    Name        = "odoo-spot-instance"
    Environment = var.environment
    Project     = "Helipistas-Odoo-17"
    Type        = "Spot"
    AutoRecover = "true"
  }
}

# ============================================
# LAUNCH TEMPLATE - Con lista de instancias
# ============================================

resource "aws_launch_template" "odoo_spot" {
  name_prefix   = "odoo-spot-"
  image_id      = data.aws_ami.amazon_linux_2.id
  key_name      = var.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.spot_instance_profile.name
  }

  vpc_security_group_ids = [aws_security_group.odoo_spot_sg.id]

  # User data
  user_data = base64encode(templatefile("${path.module}/user_data_spot.sh", {
    efs_id            = var.efs_id
    efs_mount_point   = var.efs_mount_point
    ebs_device        = var.ebs_volume_size > 0 ? "/dev/xvdf" : ""
    ebs_mount_point   = var.ebs_mount_point
    postgres_password = var.postgres_password
    github_repo       = var.github_repo
    github_branch     = var.github_branch
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # Opciones de mercado Spot con alternativas
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "persistent"
      max_price                      = var.spot_max_price
    }
  }

  # Metadatos opcionales
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "odoo-spot-instance"
      Environment = var.environment
      Project     = "Helipistas-Odoo-17"
    }
  }
}

# ============================================
# FLEET REQUEST - Con lista de tipos de instancia
# ============================================
# Este enfoque permite especificar múltiples tipos

resource "aws_ec2_fleet" "odoo_spot_fleet" {
  count = var.use_fleet_instead_of_spot_request ? 1 : 0

  # Lanzar solo 1 instancia
  target_capacity_specification {
    default_target_capacity_type = "spot"
    total_target_capacity        = 1
  }

  # Reemplazar automáticamente si se termina
  type = "maintain"

  # Terminar al eliminar el fleet
  terminate_instances                 = true
  terminate_instances_with_expiration = false

  # Configuración de Spot
  spot_options {
    allocation_strategy            = "price-capacity-optimized"
    instance_interruption_behavior = "terminate"
  }

  # Lista de configuraciones de lanzamiento con tipos alternativos
  dynamic "launch_template_config" {
    for_each = var.instance_types_alternatives
    content {
      launch_template_specification {
        launch_template_id = aws_launch_template.odoo_spot.id
        version            = "$Latest"
      }

      # Sobrescribir tipo de instancia
      override {
        instance_type = launch_template_config.value
        subnet_id     = var.subnet_id
      }
    }
  }

  tags = {
    Name        = "odoo-spot-fleet"
    Environment = var.environment
    Project     = "Helipistas-Odoo-17"
  }
}

# Asociar EBS volume a la instancia (si existe y se usa Spot Request)
resource "aws_volume_attachment" "spot_data_attachment" {
  count       = var.ebs_volume_size > 0 && !var.use_fleet_instead_of_spot_request ? 1 : 0
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.spot_data[0].id
  instance_id = aws_spot_instance_request.odoo_spot[0].spot_instance_id

  # No forzar detach en destroy (mantener datos)
  force_detach = false
  skip_destroy = var.ebs_skip_destroy
}

# ============================================
# OUTPUTS - Información de la instancia
# ============================================

output "deployment_type" {
  description = "Tipo de deployment usado"
  value       = var.use_fleet_instead_of_spot_request ? "EC2 Fleet" : "Spot Instance Request"
}

output "spot_request_id" {
  description = "ID del Spot Request (si se usa)"
  value       = var.use_fleet_instead_of_spot_request ? "N/A (usando Fleet)" : aws_spot_instance_request.odoo_spot[0].id
}

output "fleet_id" {
  description = "ID del Fleet (si se usa)"
  value       = var.use_fleet_instead_of_spot_request ? aws_ec2_fleet.odoo_spot_fleet[0].id : "N/A (usando Spot Request)"
}

output "instance_types" {
  description = "Tipos de instancia configurados"
  value       = var.instance_types_alternatives
}

output "security_group_id" {
  description = "ID del Security Group"
  value       = aws_security_group.odoo_spot_sg.id
}

output "efs_mount_point" {
  description = "Punto de montaje de EFS"
  value       = var.efs_mount_point
}

output "ebs_volume_id" {
  description = "ID del volumen EBS (si existe)"
  value       = var.ebs_volume_size > 0 ? aws_ebs_volume.spot_data[0].id : "N/A"
}

output "access_info" {
  description = "Información de acceso"
  value       = <<-EOT
    1. Obtener IP pública:
       aws ec2 describe-instances --filters "Name=tag:Name,Values=odoo-spot-instance" --query 'Reservations[0].Instances[0].PublicIpAddress'
    
    2. SSH:
       ssh -i ${var.key_name}.pem ec2-user@<IP_PUBLICA>
    
    3. Odoo:
       http://<IP_PUBLICA>:8069
  EOT
}
