# Variables for AWS infrastructure

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "helipistas-odoo"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "spot_price" {
  description = "Maximum spot price per hour"
  type        = string
  default     = "0.05"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30
}

variable "public_key" {
  description = "Public SSH key content"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH and services access (0.0.0.0/0 = acceso desde cualquier IP)"
  type        = string
  default     = "0.0.0.0/0"
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

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificates"
  type        = string
  default     = ""
}

variable "existing_elastic_ip_id" {
  description = "ID of existing Elastic IP to associate with the instance (optional)"
  type        = string
  default     = ""
}

variable "existing_efs_id" {
  description = "ID of existing EFS file system to mount (optional)"
  type        = string
  default     = ""
}

variable "efs_mount_point" {
  description = "Mount point for EFS in the EC2 instance"
  type        = string
  default     = "/opt/odoo/data"
}
