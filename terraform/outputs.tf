# Outputs from Terraform deployment

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_spot_instance_request.main.spot_instance_id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = var.existing_elastic_ip_id != "" ? data.aws_eip.existing[0].public_ip : aws_eip.main[0].public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = var.existing_elastic_ip_id != "" ? data.aws_eip.existing[0].public_dns : aws_eip.main[0].public_dns
}

output "elastic_ip_id" {
  description = "ID of the Elastic IP being used"
  value       = var.existing_elastic_ip_id != "" ? data.aws_eip.existing[0].id : aws_eip.main[0].id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.project_name}-key ec2-user@${var.existing_elastic_ip_id != "" ? data.aws_eip.existing[0].public_ip : aws_eip.main[0].public_ip}"
}

output "odoo_url" {
  description = "URL to access Odoo"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${var.existing_elastic_ip_id != "" ? data.aws_eip.existing[0].public_ip : aws_eip.main[0].public_ip}"
}

output "efs_id" {
  description = "ID of the EFS file system being used (if any)"
  value       = var.existing_efs_id != "" ? var.existing_efs_id : "No EFS configured"
}

output "efs_mount_point" {
  description = "Mount point for EFS on the EC2 instance"
  value       = var.existing_efs_id != "" ? var.efs_mount_point : "No EFS configured"
}

output "spot_instance_request_id" {
  description = "ID of the spot instance request"
  value       = aws_spot_instance_request.main.id
}
