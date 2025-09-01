#!/bin/bash

# Setup script para Helipistas Odoo 17 ERP
# Este script configura Docker Compose con PostgreSQL, Odoo y Nginx

set -e

echo "=== HELIPISTAS ODOO 17 SETUP ==="
echo "Iniciando configuración en $(date)"
echo "PROJECT_DIR: $PROJECT_DIR"

# Verificar que PROJECT_DIR esté definido
if [ -z "$PROJECT_DIR" ]; then
    echo "ERROR: PROJECT_DIR no está definido"
    exit 1
fi

# Crear archivo .env con variables
cat > .env << EOF
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ODOO_MASTER_PASSWORD=${ODOO_MASTER_PASSWORD}
PROJECT_DIR=${PROJECT_DIR}
EOF

echo "✓ Archivo .env creado"

# Crear docker-compose.yml optimizado para EFS
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgresql:
    image: postgres:15
    container_name: helipistas_postgresql
    restart: unless-stopped
    environment:
      POSTGRES_DB: odoo
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ${PROJECT_DIR}/POSTGRESQL/data:/var/lib/postgresql/data
    networks:
      - helipistas_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo"]
      interval: 10s
      timeout: 5s
      retries: 5
    
  odoo:
    image: odoo:17
    container_name: helipistas_odoo
    restart: unless-stopped
    depends_on:
      postgresql:
        condition: service_healthy
    environment:
      HOST: postgresql
      USER: odoo
      PASSWORD: ${POSTGRES_PASSWORD}
      ODOO_RC: /etc/odoo/odoo.conf
    volumes:
      - ${PROJECT_DIR}/ODOO/data:/var/lib/odoo
      - ${PROJECT_DIR}/ODOO/addons:/mnt/extra-addons
      - ${PROJECT_DIR}/ODOO/config:/etc/odoo
      - ${PROJECT_DIR}/ODOO/logs:/var/log/odoo
    ports:
      - "8069:8069"
      - "8072:8072"
    networks:
      - helipistas_network
    command: ["odoo", "-c", "/etc/odoo/odoo.conf"]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8069/web/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: helipistas_nginx
    restart: unless-stopped
    depends_on:
      odoo:
        condition: service_healthy
    volumes:
      - ${PROJECT_DIR}/NGINX/conf:/etc/nginx/conf.d
      - ${PROJECT_DIR}/NGINX/ssl:/etc/nginx/ssl
      - ${PROJECT_DIR}/NGINX/logs:/var/log/nginx
      - ${PROJECT_DIR}/NGINX/cache:/var/cache/nginx
    ports:
      - "80:80"
      - "443:443"
    networks:
      - helipistas_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  helipistas_network:
    driver: bridge
    name: helipistas_odoo_network
EOF

echo "✓ docker-compose.yml creado"

# Crear configuración de Odoo
cat > "${PROJECT_DIR}/ODOO/config/odoo.conf" << EOF
[options]
# Configuración de Odoo para HELIPISTAS ERP
admin_passwd = ${ODOO_MASTER_PASSWORD}
db_host = postgresql
db_port = 5432
db_user = odoo
db_password = ${POSTGRES_PASSWORD}
db_maxconn = 64
db_template = template0

# Configuración de directorios
data_dir = /var/lib/odoo
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons

# Configuración de red y proxy
proxy_mode = True
xmlrpc_interface = 0.0.0.0
xmlrpc_port = 8069
longpolling_port = 8072

# Configuración de logs
log_level = info
log_handler = :INFO
logfile = /var/log/odoo/odoo.log
log_rotate = True
log_max_size = 104857600
log_backup_count = 5

# Configuración de rendimiento
workers = 0
max_cron_threads = 2
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_time_cpu = 600
limit_time_real = 1200
limit_request = 8192

# Configuración de seguridad
list_db = False
without_demo = True
EOF

echo "✓ Configuración de Odoo creada"

# Crear configuración de Nginx
cat > "${PROJECT_DIR}/NGINX/conf/default.conf" << 'EOF'
upstream odoo {
    server helipistas_odoo:8069;
}

upstream odoochat {
    server helipistas_odoo:8072;
}

proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=odoo_cache:10m max_size=1g inactive=60m use_temp_path=off;

server {
    listen 80;
    server_name _;
    
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_redirect off;

    access_log /var/log/nginx/odoo_access.log;
    error_log /var/log/nginx/odoo_error.log;

    client_max_body_size 200m;

    location / {
        proxy_pass http://odoo;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_buffering off;
        proxy_set_header Host $http_host;
    }

    location /longpolling {
        proxy_pass http://odoochat;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $http_host;
    }

    location ~* /web/static/ {
        proxy_cache odoo_cache;
        proxy_cache_valid 200 90m;
        proxy_cache_valid 404 1m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
        add_header X-Cache-Status $upstream_cache_status;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)$ {
        proxy_cache odoo_cache;
        proxy_cache_valid 200 30d;
        proxy_cache_valid 404 1m;
        expires 30d;
        add_header Cache-Control "public, immutable";
        proxy_pass http://odoo;
        add_header X-Cache-Status $upstream_cache_status;
    }

    location /nginx-health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

echo "✓ Configuración de Nginx creada"

# Ajustar permisos para todos los directorios EFS
chown -R ec2-user:ec2-user "${PROJECT_DIR}"
chmod -R 755 "${PROJECT_DIR}"

# Permisos específicos para PostgreSQL (necesita 700)
chmod 700 "${PROJECT_DIR}/POSTGRESQL/data"

# Crear directorios de logs si no existen
mkdir -p "${PROJECT_DIR}/ODOO/logs" "${PROJECT_DIR}/NGINX/logs"

echo "✓ Permisos configurados"

# Iniciar servicios Docker
echo "Iniciando servicios Docker..."
docker-compose up -d

echo "✓ Servicios Docker iniciados"

# Esperar a que los servicios estén listos
echo "Esperando a que los servicios estén listos..."
sleep 30

# Verificar estado de los contenedores
docker-compose ps

echo "=== SETUP COMPLETADO ==="
echo "Odoo disponible en: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8069"
echo "Nginx disponible en: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Fecha de finalización: $(date)"
