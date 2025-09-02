# Variables simplificadas para Helipistas Odoo 17

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "resource_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "HELIPISTAS-ODOO-17"
}

variable "instance_type" {
  description = "EC2 instance type principal"
  type        = string
  default     = "t3.medium"
}

variable "instance_types" {
  description = "Lista de tipos de instancia alternativos para spot instances"
  type        = list(string)
  default     = ["t3.medium", "t3a.medium", "t2.medium", "m5.large", "m5a.large", "m4.large"]
}

variable "spot_price" {
  description = "Precio máximo para spot instances (USD por hora)"
  type        = string
  default     = "0.10"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "key_pair_name" {
  description = "Name of existing AWS Key Pair"
  type        = string
}

variable "odoo_master_password" {
  description = "Odoo master password"
  type        = string
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "existing_elastic_ip_id" {
  description = "ID of existing Elastic IP to use"
  type        = string
  default     = ""
}

variable "existing_efs_id" {
  description = "ID of existing EFS file system to mount"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for SSL certificate"
  type        = string
  default     = "erp17.helipistas.com"
}
