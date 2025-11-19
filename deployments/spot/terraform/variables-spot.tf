# ============================================
# VARIABLES - Configuración Spot Deployment
# ============================================

# -------------------- AWS --------------------

variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Entorno (development, staging, etc.)"
  type        = string
  default     = "development"
}

# -------------------- NETWORK --------------------

variable "vpc_id" {
  description = "ID de la VPC existente"
  type        = string
  default     = "vpc-92d074f6"
}

variable "subnet_id" {
  description = "ID de la subnet existente"
  type        = string
  default     = "subnet-c362e2a7"
}

variable "allowed_ssh_cidr" {
  description = "CIDR permitido para SSH (tu IP)"
  type        = string
  # Cambiar por tu IP pública (ej: "1.2.3.4/32")
}

# -------------------- EC2 SPOT --------------------

variable "instance_type" {
  description = "Tipo de instancia EC2"
  type        = string
  default     = "t3.medium"
  # Alternativas: t3.small (más barato), t3.large (más potente)
}

variable "key_name" {
  description = "Nombre de la llave SSH (sin extensión .pem)"
  type        = string
  default     = "ERP"
}

variable "spot_max_price" {
  description = "Precio máximo por hora para Spot (null = precio on-demand)"
  type        = string
  default     = null
  # Ejemplo: "0.05" para máximo $0.05/hora
  # null = pagar hasta precio on-demand (garantiza disponibilidad)
}

variable "spot_valid_until" {
  description = "Fecha hasta la cual el Spot Request es válido (ISO 8601)"
  type        = string
  default     = "2026-12-31T23:59:59Z"
  # Spot Request se cancela automáticamente después de esta fecha
}

# -------------------- STORAGE --------------------

variable "root_volume_size" {
  description = "Tamaño del volumen root en GB"
  type        = number
  default     = 20
}

variable "efs_id" {
  description = "ID del EFS existente (o crear uno nuevo)"
  type        = string
  default     = "fs-ec7152d9"
  # Cambiar si quieres usar un EFS diferente
}

variable "efs_mount_point" {
  description = "Punto de montaje de EFS en la instancia"
  type        = string
  default     = "/efs/HELIPISTAS-ODOO-17-DEV"
}

variable "ebs_volume_size" {
  description = "Tamaño del volumen EBS adicional en GB (0 = no crear)"
  type        = number
  default     = 0
  # Ejemplo: 50 para crear un volumen de 50GB
  # 0 = no crear volumen adicional (solo usar EFS)
}

variable "ebs_volume_type" {
  description = "Tipo de volumen EBS"
  type        = string
  default     = "gp3"
  # Opciones: gp3 (general), io1 (high performance), st1 (throughput)
}

variable "ebs_mount_point" {
  description = "Punto de montaje de EBS en la instancia"
  type        = string
  default     = "/mnt/ebs-data"
}

variable "ebs_skip_destroy" {
  description = "No destruir EBS al hacer terraform destroy (mantener datos)"
  type        = bool
  default     = true
}

# -------------------- APPLICATION --------------------

variable "domain_name" {
  description = "Dominio para acceder a Odoo"
  type        = string
  default     = "dev.helipistas.com"
}

variable "route53_zone_id" {
  description = "ID de la zona de Route 53 para actualizar DNS"
  type        = string
  # Obtener con: aws route53 list-hosted-zones
}

variable "postgres_password" {
  description = "Contraseña para PostgreSQL"
  type        = string
  sensitive   = true
  # NUNCA hacer commit de esta variable en terraform.tfvars
}

variable "github_repo" {
  description = "Repositorio de GitHub (owner/repo)"
  type        = string
  default     = "leulit/helipistas-erp-odoo-17-server-scripts"
}

variable "github_branch" {
  description = "Rama de GitHub para descargar scripts"
  type        = string
  default     = "main"
}

# -------------------- ODOO --------------------

variable "odoo_admin_password" {
  description = "Contraseña del admin de Odoo"
  type        = string
  sensitive   = true
  default     = ""
  # Si está vacía, se genera automáticamente
}

variable "odoo_workers" {
  description = "Número de workers de Odoo (0 = modo desarrollo)"
  type        = number
  default     = 2
  # 0 = desarrollo (auto-reload), 2 = producción (t3.medium)
}
