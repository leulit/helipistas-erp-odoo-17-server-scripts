#!/bin/bash
# ============================================
# SETUP SCRIPT - Configuración completa Spot Instance
# ============================================
# Este script se descarga desde GitHub y configura todo el sistema
# Puede actualizarse sin recrear la infraestructura Terraform
# ============================================

set -e  # Salir en caso de error

# -------------------- PARÁMETROS --------------------
EFS_ID=$1
EFS_MOUNT=$2
EBS_DEVICE=$3
EBS_MOUNT=$4
DOMAIN=$5
DB_PASS=$6
GITHUB_REPO=$7
GITHUB_BRANCH=$8
ROUTE53_ZONE_ID=$9

# -------------------- LOGGING --------------------
exec > >(tee -a /var/log/setup.log)
exec 2>&1

echo "=========================================="
echo "=== SETUP SPOT INSTANCE - $(date) ==="
echo "=========================================="
echo "Parámetros recibidos:"
echo "  EFS_ID: $EFS_ID"
echo "  EFS_MOUNT: $EFS_MOUNT"
echo "  EBS_DEVICE: $EBS_DEVICE"
echo "  EBS_MOUNT: $EBS_MOUNT"
echo "  DOMAIN: $DOMAIN"
echo "  GITHUB_REPO: $GITHUB_REPO"
echo "  GITHUB_BRANCH: $GITHUB_BRANCH"
echo "  ROUTE53_ZONE_ID: $ROUTE53_ZONE_ID"
echo "=========================================="

# -------------------- 1. INSTALAR DEPENDENCIAS --------------------
echo ""
echo "=========================================="
echo "=== 1. INSTALANDO DEPENDENCIAS ==="
echo "=========================================="

echo "Instalando Docker, AWS CLI, EFS utils..."
yum install -y \
  docker \
  amazon-efs-utils \
  aws-cli \
  git \
  htop

# Instalar Docker Compose
echo "Instalando Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Iniciar Docker
echo "Iniciando servicio Docker..."
systemctl enable docker
systemctl start docker

# Verificar instalación
docker --version
docker-compose --version

echo "✅ Dependencias instaladas correctamente"

# -------------------- 2. MONTAR EFS --------------------
echo ""
echo "=========================================="
echo "=== 2. MONTANDO EFS ==="
echo "=========================================="

echo "Creando punto de montaje: $EFS_MOUNT"
mkdir -p "$EFS_MOUNT"

echo "Montando EFS: $EFS_ID"
# Montar con TLS para seguridad
mount -t efs -o tls "$EFS_ID":/ "$EFS_MOUNT"

# Agregar a fstab para montaje automático
if ! grep -q "$EFS_ID" /etc/fstab; then
  echo "$EFS_ID:/ $EFS_MOUNT efs _netdev,tls 0 0" >> /etc/fstab
fi

# Verificar montaje
df -h | grep "$EFS_MOUNT"

echo "✅ EFS montado correctamente en $EFS_MOUNT"

# -------------------- 3. MONTAR EBS (si existe) --------------------
if [ -n "$EBS_DEVICE" ] && [ "$EBS_DEVICE" != "" ]; then
  echo ""
  echo "=========================================="
  echo "=== 3. MONTANDO EBS ==="
  echo "=========================================="
  
  echo "Creando punto de montaje: $EBS_MOUNT"
  mkdir -p "$EBS_MOUNT"
  
  # Esperar a que el dispositivo esté disponible
  echo "Esperando dispositivo: $EBS_DEVICE"
  for i in {1..30}; do
    if [ -e "$EBS_DEVICE" ]; then
      echo "Dispositivo encontrado"
      break
    fi
    echo "Intento $i/30..."
    sleep 2
  done
  
  # Formatear si no tiene filesystem
  if ! blkid "$EBS_DEVICE" | grep -q TYPE; then
    echo "Formateando $EBS_DEVICE con ext4..."
    mkfs.ext4 "$EBS_DEVICE"
  else
    echo "Dispositivo ya tiene filesystem"
  fi
  
  # Montar
  echo "Montando $EBS_DEVICE en $EBS_MOUNT"
  mount "$EBS_DEVICE" "$EBS_MOUNT"
  
  # Agregar a fstab
  if ! grep -q "$EBS_DEVICE" /etc/fstab; then
    echo "$EBS_DEVICE $EBS_MOUNT ext4 defaults,nofail 0 2" >> /etc/fstab
  fi
  
  # Verificar montaje
  df -h | grep "$EBS_MOUNT"
  
  echo "✅ EBS montado correctamente en $EBS_MOUNT"
else
  echo ""
  echo "⏭️  No se configuró EBS adicional (solo EFS)"
fi

# -------------------- 4. CREAR ESTRUCTURA DE DIRECTORIOS --------------------
echo ""
echo "=========================================="
echo "=== 4. CREANDO ESTRUCTURA DE DIRECTORIOS ==="
echo "=========================================="

cd "$EFS_MOUNT"

# Crear directorios para PostgreSQL
echo "Creando directorios para PostgreSQL..."
mkdir -p postgres

# Crear directorios para Odoo
echo "Creando directorios para Odoo..."
mkdir -p odoo/conf
mkdir -p odoo/addons
mkdir -p odoo/filestore
mkdir -p odoo/sessions

# Crear directorios para Nginx
echo "Creando directorios para Nginx..."
mkdir -p nginx/conf

# Crear directorios para Certbot
echo "Creando directorios para Certbot..."
mkdir -p certbot/conf
mkdir -p certbot/www

# Permisos correctos para Docker
echo "Configurando permisos..."
chown -R 101:101 postgres     # UID de postgres en Docker
chown -R 101:101 odoo         # UID de odoo en Docker
chmod -R 755 nginx certbot

echo "✅ Estructura de directorios creada"

# -------------------- 5. OBTENER IP PÚBLICA --------------------
echo ""
echo "=========================================="
echo "=== 5. DETECTANDO IP PÚBLICA ==="
echo "=========================================="

INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "IP pública detectada: $INSTANCE_IP"

# -------------------- 6. ACTUALIZAR DNS (Route 53) --------------------
echo ""
echo "=========================================="
echo "=== 6. ACTUALIZANDO DNS (Route 53) ==="
echo "=========================================="

echo "Actualizando $DOMAIN → $INSTANCE_IP"

aws route53 change-resource-record-sets \
  --hosted-zone-id "$ROUTE53_ZONE_ID" \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$DOMAIN\",
        \"Type\": \"A\",
        \"TTL\": 60,
        \"ResourceRecords\": [{\"Value\": \"$INSTANCE_IP\"}]
      }
    }]
  }"

echo "✅ DNS actualizado: $DOMAIN → $INSTANCE_IP"
echo "Esperando propagación DNS (60 segundos)..."
sleep 60

# -------------------- 7. DESCARGAR ARCHIVOS DE CONFIGURACIÓN --------------------
echo ""
echo "=========================================="
echo "=== 7. DESCARGANDO ARCHIVOS DE CONFIGURACIÓN ==="
echo "=========================================="

cd "$EFS_MOUNT"
BASE_URL="https://raw.githubusercontent.com/$GITHUB_REPO/$GITHUB_BRANCH/deployments/spot"

# Docker Compose
echo "Descargando docker-compose.yml..."
wget -O docker-compose.yml "$BASE_URL/docker-compose.yml"

# Nginx
echo "Descargando configuración de Nginx..."
wget -O nginx/conf/nginx.conf "$BASE_URL/nginx.conf"
wget -O nginx/conf/default.conf.template "$BASE_URL/default.conf.template"

# Odoo
echo "Descargando configuración de Odoo..."
wget -O odoo/conf/odoo.conf.template "$BASE_URL/odoo.conf.template"

echo "✅ Archivos de configuración descargados"

# -------------------- 8. PROCESAR TEMPLATES Y CREAR .ENV --------------------
echo ""
echo "=========================================="
echo "=== 8. PROCESANDO CONFIGURACIÓN ==="
echo "=========================================="

# Generar contraseña de admin si no existe
ADMIN_PASSWORD=$(openssl rand -base64 32)

# Crear .env
cat > .env << EOF
# Dominio
DOMAIN_NAME=$DOMAIN

# PostgreSQL
POSTGRES_USER=odoo
POSTGRES_PASSWORD=$DB_PASS
POSTGRES_DB=postgres

# Odoo
ODOO_DB_HOST=postgresOdoo17
ODOO_DB_USER=odoo
ODOO_DB_PASSWORD=$DB_PASS

# Rutas
EFS_MOUNT_POINT=$EFS_MOUNT
EBS_MOUNT_POINT=$EBS_MOUNT

# Email para Let's Encrypt
LETSENCRYPT_EMAIL=admin@helipistas.com

# Admin password (generada)
ADMIN_PASSWORD=$ADMIN_PASSWORD
EOF

echo "✅ Archivo .env creado"

# Procesar template de Nginx
echo "Procesando configuración de Nginx..."
sed "s/\${DOMAIN_NAME}/$DOMAIN/g" nginx/conf/default.conf.template > nginx/conf/default.conf

# Procesar template de Odoo
echo "Procesando configuración de Odoo..."
sed -e "s/\${POSTGRES_PASSWORD}/$DB_PASS/g" \
    -e "s/\${ADMIN_PASSWORD}/$ADMIN_PASSWORD/g" \
    odoo/conf/odoo.conf.template > odoo/conf/odoo.conf

echo "✅ Configuraciones procesadas"

# Guardar contraseña de admin en lugar seguro
echo "$ADMIN_PASSWORD" > /root/odoo_admin_password.txt
chmod 600 /root/odoo_admin_password.txt
echo "⚠️  Contraseña de admin guardada en: /root/odoo_admin_password.txt"

# -------------------- 9. OBTENER CERTIFICADO SSL --------------------
echo ""
echo "=========================================="
echo "=== 9. OBTENIENDO CERTIFICADO SSL ==="
echo "=========================================="

# Primero iniciar Nginx sin SSL para challenge HTTP
echo "Iniciando Nginx (modo HTTP)..."
cd "$EFS_MOUNT"

# Crear configuración temporal sin SSL
cat > nginx/conf/default.conf << NGINXTEMP
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        proxy_pass http://odooApp:8069;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINXTEMP

# Iniciar solo nginx temporalmente
docker-compose up -d nginx

sleep 10

# Obtener certificado con DNS challenge (Route 53)
echo "Solicitando certificado SSL para $DOMAIN..."
docker run --rm \
  -v "$EFS_MOUNT/certbot/conf:/etc/letsencrypt" \
  -v "$EFS_MOUNT/certbot/www:/var/www/certbot" \
  --env AWS_DEFAULT_REGION=eu-west-1 \
  certbot/dns-route53 certonly \
  --dns-route53 \
  --non-interactive \
  --agree-tos \
  --email admin@helipistas.com \
  --domains "$DOMAIN"

# Verificar si se obtuvo el certificado
if [ -f "$EFS_MOUNT/certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
  echo "✅ Certificado SSL obtenido correctamente"
  
  # Restaurar configuración de Nginx con SSL
  sed "s/\${DOMAIN_NAME}/$DOMAIN/g" nginx/conf/default.conf.template > nginx/conf/default.conf
  
  # Reiniciar nginx con SSL
  docker-compose restart nginx
else
  echo "⚠️  No se pudo obtener certificado SSL"
  echo "El sistema funcionará solo con HTTP"
fi

# -------------------- 10. INICIAR TODOS LOS SERVICIOS --------------------
echo ""
echo "=========================================="
echo "=== 10. INICIANDO TODOS LOS SERVICIOS ==="
echo "=========================================="

cd "$EFS_MOUNT"
docker-compose up -d

echo "Esperando a que los servicios estén listos..."
sleep 30

# Verificar estado
docker-compose ps

echo "✅ Servicios iniciados"

# -------------------- 11. INSTALAR SPOT TERMINATION HANDLER --------------------
echo ""
echo "=========================================="
echo "=== 11. INSTALANDO SPOT TERMINATION HANDLER ==="
echo "=========================================="

cat > /usr/local/bin/spot-termination-handler.sh << 'HANDLER_SCRIPT'
#!/bin/bash
# Monitorea metadata endpoint para detección de terminación

EFS_MOUNT="$EFS_MOUNT_PLACEHOLDER"

while true; do
  # Verificar metadata endpoint
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    http://169.254.169.254/latest/meta-data/spot/termination-time)
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo "$(date): ⚠️  SPOT TERMINATION NOTICE - Iniciando apagado graceful"
    
    # Apagar servicios correctamente
    cd "$EFS_MOUNT"
    docker-compose down --timeout 60
    
    # Log final
    echo "$(date): ✅ Apagado graceful completado" | tee -a /var/log/spot-termination.log
    
    # Enviar notificación (opcional)
    # aws sns publish --topic-arn ... --message "Spot Instance terminada"
    
    exit 0
  fi
  
  # Verificar cada 5 segundos
  sleep 5
done
HANDLER_SCRIPT

# Reemplazar placeholder con valor real
sed -i "s|EFS_MOUNT_PLACEHOLDER|$EFS_MOUNT|g" /usr/local/bin/spot-termination-handler.sh
chmod +x /usr/local/bin/spot-termination-handler.sh

# Crear servicio systemd
cat > /etc/systemd/system/spot-termination-handler.service << 'SERVICE_UNIT'
[Unit]
Description=Spot Instance Termination Handler
After=docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=/usr/local/bin/spot-termination-handler.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE_UNIT

# Activar servicio
systemctl daemon-reload
systemctl enable spot-termination-handler
systemctl start spot-termination-handler

echo "✅ Spot Termination Handler instalado y activo"

# -------------------- 12. VERIFICACIONES FINALES --------------------
echo ""
echo "=========================================="
echo "=== 12. VERIFICACIONES FINALES ==="
echo "=========================================="

echo "Verificando montajes:"
df -h | grep -E "(efs|ebs)"

echo ""
echo "Verificando servicios Docker:"
docker-compose ps

echo ""
echo "Verificando handler:"
systemctl status spot-termination-handler --no-pager

# -------------------- COMPLETION --------------------
echo ""
echo "=========================================="
echo "=== ✅ SETUP COMPLETADO - $(date) ==="
echo "=========================================="
echo ""
echo "📋 INFORMACIÓN DEL DEPLOYMENT:"
echo "  Dominio: https://$DOMAIN"
echo "  IP Pública: $INSTANCE_IP"
echo "  EFS: $EFS_MOUNT"
[ -n "$EBS_DEVICE" ] && echo "  EBS: $EBS_MOUNT"
echo ""
echo "📝 LOGS:"
echo "  Setup: /var/log/setup.log"
echo "  User Data: /var/log/user-data.log"
echo "  Termination: /var/log/spot-termination.log"
echo ""
echo "🔧 COMANDOS ÚTILES:"
echo "  Ver servicios: docker-compose ps"
echo "  Ver logs: docker-compose logs -f"
echo "  Reiniciar: docker-compose restart"
echo ""
echo "⚠️  IMPORTANTE:"
echo "  Esta instancia puede ser terminada por AWS en cualquier momento"
echo "  El Spot Request es PERSISTENTE: se recreará automáticamente"
echo "  Downtime esperado: 2-3 minutos durante recreación"
echo "  Datos en EFS están protegidos y persisten"
echo ""
echo "=========================================="
