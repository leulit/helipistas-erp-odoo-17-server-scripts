#!/bin/bash
cd /Users/emiloalvarez/Work/PROYECTOS/HELIPISTAS/ODOO-17-2025/SERVER-SCRIPTS/terraform
echo "=== DIRECTORIO ACTUAL ==="
pwd
echo "=== ARCHIVOS TERRAFORM ==="
ls -la *.tf
echo "=== TERRAFORM PLAN ==="
terraform plan
echo "=== TERRAFORM APPLY ==="
terraform apply -auto-approve
