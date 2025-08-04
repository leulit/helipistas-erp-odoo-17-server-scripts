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
  value       = aws_eip.main.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.main.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.project_name}-key ec2-user@${aws_eip.main.public_ip}"
}

output "odoo_url" {
  description = "URL to access Odoo"
  value       = var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_eip.main.public_ip}"
}

output "spot_instance_request_id" {
  description = "ID of the spot instance request"
  value       = aws_spot_instance_request.main.id
}
