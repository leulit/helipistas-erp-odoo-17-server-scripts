#!/bin/bash
# ============================================
# USER DATA - Bootstrap mínimo para Spot Instance
# ============================================
# Este script se ejecuta AUTOMÁTICAMENTE al crear la instancia
# Solo hace lo mínimo necesario para descargar y ejecutar setup.sh
# ============================================

set -e  # Salir en caso de error

# -------------------- LOGGING --------------------
exec > >(tee /var/log/user-data.log)
exec 2>&1
echo "=========================================="
echo "=== USER DATA STARTED $(date) ==="
echo "=========================================="

# -------------------- SYSTEM UPDATE --------------------
echo "=== 1. Actualizando sistema operativo ==="
yum update -y

# -------------------- INSTALL MINIMAL TOOLS --------------------
echo "=== 2. Instalando herramientas básicas ==="
yum install -y wget curl jq

# -------------------- DOWNLOAD SETUP SCRIPT --------------------
echo "=== 3. Descargando setup.sh desde GitHub ==="
SETUP_URL="https://raw.githubusercontent.com/${github_repo}/${github_branch}/deployments/spot/setup.sh"
echo "URL: $SETUP_URL"

wget -O /tmp/setup.sh "$SETUP_URL"
chmod +x /tmp/setup.sh

# -------------------- EXECUTE SETUP --------------------
echo "=== 4. Ejecutando setup.sh con parámetros ==="
/tmp/setup.sh \
  "${efs_id}" \
  "${efs_mount_point}" \
  "${ebs_device}" \
  "${ebs_mount_point}" \
  "${domain_name}" \
  "${postgres_password}" \
  "${github_repo}" \
  "${github_branch}" \
  "${route53_zone_id}" \
  >> /var/log/setup.log 2>&1

# -------------------- COMPLETION --------------------
echo "=========================================="
echo "=== USER DATA COMPLETED $(date) ==="
echo "=========================================="
echo "Ver logs completos en /var/log/setup.log"
