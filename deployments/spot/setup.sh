#!/bin/bash
# ============================================
# SETUP SCRIPT - Configuración Spot Instance
# ============================================
# Script descargable desde GitHub
# Solo hace lo solicitado: montar EFS/EBS, descargar docker-compose, iniciarlo
# ============================================

set -e  # Salir en caso de error

# -------------------- PARÁMETROS --------------------
EFS_ID=$1
EFS_MOUNT=$2
EBS_DEVICE=$3
EBS_MOUNT=$4
DB_PASS=$5
GITHUB_REPO=$6
GITHUB_BRANCH=$7

# -------------------- LOGGING --------------------
exec > >(tee -a /var/log/setup.log)
exec 2>&1

echo "=========================================="
echo "=== SETUP SPOT INSTANCE - $(date) ==="
echo "=========================================="
echo "Parámetros:"
echo "  EFS_ID: $EFS_ID"
echo "  EFS_MOUNT: $EFS_MOUNT"
echo "  EBS_DEVICE: $EBS_DEVICE"
echo "  EBS_MOUNT: $EBS_MOUNT"
echo "  GITHUB_REPO: $GITHUB_REPO"
echo "  GITHUB_BRANCH: $GITHUB_BRANCH"
echo "=========================================="

# -------------------- 1. INSTALAR DEPENDENCIAS --------------------
echo ""
echo "=========================================="
echo "=== 1. INSTALANDO DEPENDENCIAS ==="
echo "=========================================="

yum install -y docker amazon-efs-utils aws-cli git htop

# Docker Compose
echo "Instalando Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

systemctl enable docker
systemctl start docker

docker --version
docker-compose --version

echo "✅ Dependencias instaladas"

# -------------------- 2. MONTAR EFS --------------------
echo ""
echo "=========================================="
echo "=== 2. MONTANDO EFS ==="
echo "=========================================="

mkdir -p "$EFS_MOUNT"
mount -t efs -o tls "$EFS_ID":/ "$EFS_MOUNT"

if ! grep -q "$EFS_ID" /etc/fstab; then
  echo "$EFS_ID:/ $EFS_MOUNT efs _netdev,tls 0 0" >> /etc/fstab
fi

df -h | grep "$EFS_MOUNT"
echo "✅ EFS montado en $EFS_MOUNT"

# -------------------- 3. MONTAR EBS (si existe) --------------------
if [ -n "$EBS_DEVICE" ] && [ "$EBS_DEVICE" != "" ]; then
  echo ""
  echo "=========================================="
  echo "=== 3. MONTANDO EBS ==="
  echo "=========================================="
  
  mkdir -p "$EBS_MOUNT"
  
  # Esperar dispositivo
  for i in {1..30}; do
    [ -e "$EBS_DEVICE" ] && break
    sleep 2
  done
  
  # Formatear si es necesario
  if ! blkid "$EBS_DEVICE" | grep -q TYPE; then
    mkfs.ext4 "$EBS_DEVICE"
  fi
  
  mount "$EBS_DEVICE" "$EBS_MOUNT"
  
  if ! grep -q "$EBS_DEVICE" /etc/fstab; then
    echo "$EBS_DEVICE $EBS_MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  
  df -h | grep "$EBS_MOUNT"
  echo "✅ EBS montado en $EBS_MOUNT"
else
  echo ""
  echo "⏭️  No se configuró EBS"
fi

# -------------------- 4. ESTRUCTURA DE DIRECTORIOS --------------------
echo ""
echo "=========================================="
echo "=== 4. CREANDO DIRECTORIOS ==="
echo "=========================================="

cd "$EFS_MOUNT"
mkdir -p postgres odoo/addons odoo/filestore odoo/sessions

# Permisos Docker
chown -R 101:101 postgres odoo

echo "✅ Directorios creados"

# -------------------- 5. DESCARGAR DOCKER-COMPOSE --------------------
echo ""
echo "=========================================="
echo "=== 5. DESCARGANDO DOCKER-COMPOSE.YML ==="
echo "=========================================="

BASE_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/deployments/spot"
wget -O docker-compose.yml "$BASE_URL/docker-compose.yml"

echo "✅ docker-compose.yml descargado"

# -------------------- 6. CREAR .ENV --------------------
echo ""
echo "=========================================="
echo "=== 6. CREANDO .ENV ==="
echo "=========================================="

cat > .env << EOF
POSTGRES_USER=odoo
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_DB=postgres
ODOO_DB_HOST=postgresOdoo17
ODOO_DB_USER=odoo
ODOO_DB_PASSWORD=$DB_PASS
EFS_MOUNT_POINT=$EFS_MOUNT
EBS_MOUNT_POINT=$EBS_MOUNT
EOF

echo "✅ .env creado"

# -------------------- 7. INICIAR DOCKER-COMPOSE --------------------
echo ""
echo "=========================================="
echo "=== 7. INICIANDO DOCKER-COMPOSE ==="
echo "=========================================="

docker-compose up -d

sleep 30
docker-compose ps

echo "✅ Servicios iniciados"

# -------------------- 8. SPOT TERMINATION HANDLER --------------------
echo ""
echo "=========================================="
echo "=== 8. INSTALANDO TERMINATION HANDLER ==="
echo "=========================================="

cat > /usr/local/bin/spot-termination-handler.sh << 'HANDLER'
#!/bin/bash
EFS_MOUNT="EFS_MOUNT_PLACEHOLDER"

while true; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    http://169.254.169.254/latest/meta-data/spot/termination-time)
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo "$(date): SPOT TERMINATION - Apagado graceful"
    cd "$EFS_MOUNT"
    docker-compose down --timeout 60
    echo "$(date): Apagado completado" >> /var/log/spot-termination.log
    exit 0
  fi
  
  sleep 5
done
HANDLER

sed -i "s|EFS_MOUNT_PLACEHOLDER|$EFS_MOUNT|g" /usr/local/bin/spot-termination-handler.sh
chmod +x /usr/local/bin/spot-termination-handler.sh

cat > /etc/systemd/system/spot-termination-handler.service << 'SERVICE'
[Unit]
Description=Spot Termination Handler
After=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/spot-termination-handler.sh
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable spot-termination-handler
systemctl start spot-termination-handler

echo "✅ Termination Handler activo"

# -------------------- COMPLETION --------------------
echo ""
echo "=========================================="
echo "=== ✅ SETUP COMPLETADO - $(date) ==="
echo "=========================================="
echo ""
echo "📋 INFORMACIÓN:"
echo "  EFS: $EFS_MOUNT"
[ -n "$EBS_DEVICE" ] && echo "  EBS: $EBS_MOUNT"
echo ""
echo "📝 LOGS:"
echo "  /var/log/setup.log"
echo "  /var/log/user-data.log"
echo "  /var/log/spot-termination.log"
echo ""
echo "⚠️  Spot Instance con auto-recovery"
echo "  Downtime: 2-3 min si AWS termina"
echo "  Datos persistentes en EFS"
echo ""
echo "=========================================="
