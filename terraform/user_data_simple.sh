#!/bin/bash
# User Data Script MÍNIMO para Helipistas Odoo 17

set -e
# Redirigir toda la salida a logs múltiples para mejor debugging
exec > >(tee -a /var/log/user-data.log /var/log/helipistas-setup.log) 2>&1

echo "=========================================="
echo "=== INICIO SETUP HELIPISTAS ODOO 17 ==="
echo "=========================================="
echo "Fecha inicio: $(date)"
echo "Usuario: $(whoami)"
echo "Directorio actual: $(pwd)"
echo "ID de instancia: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
echo "Zona disponibilidad: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"
echo "IP privada: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
echo "IP pública: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

# Variables
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
ODOO_MASTER_PASSWORD="${ODOO_MASTER_PASSWORD}"
EFS_ID="${EFS_ID}"
ELASTIC_IP_ID="${ELASTIC_IP_ID}"

echo "=========================================="
echo "Variables recibidas:"
echo "POSTGRES_PASSWORD: [DEFINIDO]"
echo "ODOO_MASTER_PASSWORD: [DEFINIDO]"
echo "EFS_ID: $EFS_ID"
echo "ELASTIC_IP_ID: $ELASTIC_IP_ID"
echo "=========================================="

# 1. ACTUALIZAR SISTEMA E INSTALAR DEPENDENCIAS
echo "=========================================="
echo "=== 1. INSTALANDO DEPENDENCIAS ==="
echo "=========================================="
echo "Actualizando sistema..."
yum update -y

# Instalar EPEL para amazon-efs-utils
echo "Instalando EPEL..."
amazon-linux-extras install epel -y

# Instalar dependencias principales
echo "Instalando dependencias principales..."
yum install -y docker git wget curl nfs-utils aws-cli amazon-efs-utils

# Verificar que se instaló correctamente
echo "Verificando instalaciones..."
which mount.efs || echo "ADVERTENCIA: mount.efs no encontrado"
which docker || echo "ERROR: docker no encontrado"
which aws || echo "ERROR: aws cli no encontrado"

echo "Versiones instaladas:"
echo "Docker: $(docker --version 2>/dev/null || echo 'No instalado')"
echo "AWS CLI: $(aws --version 2>/dev/null || echo 'No instalado')"

# 2. CONFIGURAR DOCKER
echo "=========================================="
echo "=== 2. CONFIGURANDO DOCKER ==="
echo "=========================================="
echo "Iniciando Docker..."
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
echo "Docker configurado y iniciado"

# 3. INSTALAR DOCKER COMPOSE
echo "=========================================="
echo "=== 3. INSTALANDO DOCKER COMPOSE ==="
echo "=========================================="
echo "Descargando Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
echo "Docker Compose instalado: $(/usr/local/bin/docker-compose --version)"

# 4. MONTAR EFS
echo "=========================================="
echo "=== 4. MONTANDO EFS ==="
echo "=========================================="
mkdir -p /efs

if [ ! -z "$EFS_ID" ]; then
    echo "EFS_ID: $EFS_ID"
    echo "Montando EFS con comando que funciona..."
    
    # USAR EXACTAMENTE EL COMANDO QUE FUNCIONA EN TUS OTROS SERVIDORES
    mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-ec7152d9.efs.eu-west-1.amazonaws.com:/ /efs
    
    if mountpoint -q /efs; then
        echo "✓ EFS montado correctamente"
        # Agregar a fstab para persistencia
        echo "fs-ec7152d9.efs.eu-west-1.amazonaws.com:/ /efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab
        
        # Crear directorio del proyecto
        PROJECT_DIR="/efs/HELIPISTAS-ODOO-17"
        mkdir -p "$PROJECT_DIR"
        chown ec2-user:ec2-user "$PROJECT_DIR"
        chmod 755 "$PROJECT_DIR"
        echo "Directorio del proyecto creado: $PROJECT_DIR"
    else
        echo "✗ ERROR: EFS no se montó"
        exit 1
    fi
else
    echo "ADVERTENCIA: EFS_ID no definido, continuando sin EFS"
    PROJECT_DIR="/opt/helipistas"
    mkdir -p "$PROJECT_DIR"
fi
    
# 5. CREAR ESTRUCTURA DE DIRECTORIOS
echo "=========================================="
echo "=== 5. CREANDO DIRECTORIOS ==="
echo "=========================================="
echo "Creando estructura completa de directorios en: $PROJECT_DIR"

# Crear directorios principales
mkdir -p "$PROJECT_DIR"/{postgres,odoo,nginx,certbot}

# Crear subdirectorios específicos para Odoo
mkdir -p "$PROJECT_DIR"/odoo/{conf,addons,filestore,sessiones}

# Crear subdirectorios específicos para Nginx
mkdir -p "$PROJECT_DIR"/nginx/{conf,ssl}

# Crear subdirectorios específicos para Certbot/Let's Encrypt
mkdir -p "$PROJECT_DIR"/certbot/{conf,www}

# Establecer permisos correctos para que los contenedores puedan acceder
chown -R ec2-user:ec2-user "$PROJECT_DIR"
chmod -R 755 "$PROJECT_DIR"

# Permisos específicos para SSL y certificados
chmod 700 "$PROJECT_DIR"/nginx/ssl
chmod 700 "$PROJECT_DIR"/certbot/conf

echo "Directorio actual: $(pwd)"
echo "Estructura completa creada:"
find "$PROJECT_DIR" -type d | sort

# 6. EJECUTAR SETUP COMPLETO
echo "=========================================="
echo "=== 6. DESCARGANDO Y EJECUTANDO SETUP COMPLETO ==="
echo "=========================================="
cd "$PROJECT_DIR"

# Descargar script completo desde GitHub
echo "Descargando script de configuración completa..."
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/setup_odoo_complete.sh
chmod +x setup_odoo_complete.sh

# Ejecutar script completo con parámetros
echo "Ejecutando configuración completa..."
./setup_odoo_complete.sh "$POSTGRES_PASSWORD" "$ODOO_MASTER_PASSWORD"

echo "=========================================="
echo "=== SETUP BÁSICO COMPLETADO ==="
echo "=========================================="
echo "Fecha finalización: $(date)"
echo "Proyecto ubicado en: $PROJECT_DIR"
echo "Setup completo ejecutado exitosamente"
echo "=========================================="
