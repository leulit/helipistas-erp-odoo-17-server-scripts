# Outputs para EC2 Instance

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.main.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address"
  value       = var.existing_elastic_ip_id != "" ? "54.228.16.152" : "No Elastic IP configured"
}

output "odoo_url" {
  description = "URL to access Odoo"
  value       = "http://54.228.16.152:8069"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152"
}

output "setup_complete" {
  description = "Setup completion message"
  value       = "Deployment complete! Odoo should be available at http://54.228.16.152:8069 in a few minutes."
}
