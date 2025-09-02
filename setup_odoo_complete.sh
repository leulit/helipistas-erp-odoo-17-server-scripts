#!/bin/bash
# Setup Completo de Odoo 17 con Nginx y Let's Encrypt
# Este script se ejecuta desde /efs/HELIPISTAS-ODOO-17

set -e
exec > >(tee -a /var/log/odoo-setup-complete.log) 2>&1

echo "=========================================="
echo "=== SETUP COMPLETO ODOO 17 CON SSL ==="
echo "=========================================="
echo "Fecha inicio: $(date)"
echo "Directorio: $(pwd)"

# Parámetros recibidos
POSTGRES_PASSWORD="$1"
ODOO_MASTER_PASSWORD="$2"

if [ -z "$POSTGRES_PASSWORD" ] || [ -z "$ODOO_MASTER_PASSWORD" ]; then
    echo "ERROR: Faltan parámetros"
    echo "Uso: $0 <postgres_password> <odoo_master_password>"
    exit 1
fi

PROJECT_DIR="/efs/HELIPISTAS-ODOO-17"
cd "$PROJECT_DIR"

# 1. CORREGIR PERMISOS PARA DOCKER
echo "=========================================="
echo "=== 1. CORRIGIENDO PERMISOS ==="
echo "=========================================="
echo "Corrigiendo permisos de carpetas para Docker..."

# Establecer permisos correctos para contenedores Docker
chown -R 101:101 /efs/HELIPISTAS-ODOO-17/odoo/
chown -R 999:999 /efs/HELIPISTAS-ODOO-17/postgres/
chown -R 101:101 /efs/HELIPISTAS-ODOO-17/certbot/
chown -R 101:101 /efs/HELIPISTAS-ODOO-17/nginx/

echo "✅ Permisos corregidos para Docker"

# 2. CREAR DOCKER-COMPOSE
echo "=========================================="
echo "=== 2. CREANDO DOCKER-COMPOSE ==="
echo "=========================================="
echo "Creando docker-compose.yml con volúmenes EFS..."

cat > docker-compose.yml << EOF
version: '3.8'
services:
  postgresOdoo16:
    image: postgres:15
    container_name: helipistas_postgres
    environment:
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: $POSTGRES_PASSWORD
      POSTGRES_DB: postgres
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - /efs/HELIPISTAS-ODOO-17/postgres:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped
    networks:
      - helipistas_network

  helipistas_odoo:
    image: odoo:17
    container_name: helipistas_odoo
    depends_on:
      - postgresOdoo16
    environment:
      HOST: postgresOdoo16
      USER: odoo
      PASSWORD: $POSTGRES_PASSWORD
    volumes:
      - /efs/HELIPISTAS-ODOO-17/odoo/conf:/etc/odoo
      - /efs/HELIPISTAS-ODOO-17/odoo/addons:/mnt/extra-addons
      - /efs/HELIPISTAS-ODOO-17/odoo/filestore:/var/lib/odoo/filestore
      - /efs/HELIPISTAS-ODOO-17/odoo/sessiones:/var/lib/odoo/sessions
    ports:
      - "8069:8069"
    restart: unless-stopped
    networks:
      - helipistas_network

  nginx:
    image: nginx:latest
    container_name: helipistas_nginx
    depends_on:
      - helipistas_odoo
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /efs/HELIPISTAS-ODOO-17/nginx/conf/default.conf:/etc/nginx/conf.d/default.conf
      - /efs/HELIPISTAS-ODOO-17/nginx/ssl:/etc/nginx/ssl
      - /efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot
      - /efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt
    restart: unless-stopped
    networks:
      - helipistas_network

  certbot:
    image: certbot/certbot
    container_name: helipistas_certbot
    volumes:
      - /efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot
      - /efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt
    command: certonly --webroot --webroot-path=/var/www/certbot --email admin@helipistas.com --agree-tos --no-eff-email -d 54.228.16.152
    depends_on:
      - nginx

networks:
  helipistas_network:
    driver: bridge
EOF

echo "✅ Docker Compose creado en: $PROJECT_DIR/docker-compose.yml"

# 3. CREAR CONFIGURACIÓN NGINX INICIAL
echo "=========================================="
echo "=== 3. CONFIGURANDO NGINX ==="
echo "=========================================="
echo "Creando configuración de Nginx con Let's Encrypt..."

# Configuración inicial para HTTP (para validación Let's Encrypt)
cat > nginx/conf/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Proxy to Odoo for now (will redirect to HTTPS after SSL setup)
    location / {
        proxy_pass http://helipistas_odoo:8069;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for Odoo
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files
    location ~* /web/static/ {
        proxy_pass http://helipistas_odoo:8069;
        proxy_cache_valid 200 60m;
        proxy_buffering on;
        expires 864000;
    }
}
EOF

echo "✅ Configuración inicial de Nginx creada"

# 4. CREAR VARIABLES DE ENTORNO
echo "=========================================="
echo "=== 4. CREANDO VARIABLES DE ENTORNO ==="
echo "=========================================="
cat > .env << EOF
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
ODOO_MASTER_PASSWORD=$ODOO_MASTER_PASSWORD
EOF
echo "✅ Archivo .env creado"

# 5. INICIAR SERVICIOS
echo "=========================================="
echo "=== 5. INICIANDO SERVICIOS ==="
echo "=========================================="
echo "Iniciando stack de Docker Compose..."
/usr/local/bin/docker-compose up -d

echo "Esperando que Nginx esté listo..."
sleep 30

# 6. OBTENER CERTIFICADO LET'S ENCRYPT
echo "=========================================="
echo "=== 6. OBTENIENDO CERTIFICADO LET'S ENCRYPT ==="
echo "=========================================="
echo "Obteniendo certificado SSL de Let's Encrypt..."

# Ejecutar certbot para obtener certificado
/usr/local/bin/docker-compose run --rm certbot

# 7. VERIFICAR Y CONFIGURAR HTTPS
if [ -f "certbot/conf/live/54.228.16.152/fullchain.pem" ]; then
    echo "✅ Certificado Let's Encrypt obtenido exitosamente!"
    
    # Actualizar configuración de Nginx para usar Let's Encrypt
    echo "Actualizando configuración de Nginx para HTTPS..."
    cat > nginx/conf/default.conf << 'EOF'
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name _;
    
    # Let's Encrypt validation
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # Redirect all other traffic to HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS configuration with Let's Encrypt
server {
    listen 443 ssl http2;
    server_name _;

    # Let's Encrypt SSL certificates
    ssl_certificate /etc/letsencrypt/live/54.228.16.152/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/54.228.16.152/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Proxy settings for Odoo
    location / {
        proxy_pass http://helipistas_odoo:8069;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support for Odoo
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Static files
    location ~* /web/static/ {
        proxy_pass http://helipistas_odoo:8069;
        proxy_cache_valid 200 60m;
        proxy_buffering on;
        expires 864000;
    }
}
EOF

    # Recargar Nginx con nueva configuración HTTPS
    /usr/local/bin/docker-compose restart nginx
    
    echo "✅ HTTPS configurado con Let's Encrypt!"
else
    echo "⚠️  No se pudo obtener certificado Let's Encrypt. Usando HTTP por ahora."
    echo "Puedes obtener el certificado manualmente después del despliegue."
fi

# 8. CONFIGURAR RENOVACIÓN AUTOMÁTICA
echo "=========================================="
echo "=== 8. CONFIGURANDO RENOVACIÓN AUTOMÁTICA ==="
echo "=========================================="
echo "Configurando cron para renovación automática..."

# Crear script de renovación
cat > renew_ssl.sh << 'EOF'
#!/bin/bash
cd /efs/HELIPISTAS-ODOO-17
/usr/local/bin/docker-compose run --rm certbot renew
/usr/local/bin/docker-compose restart nginx
EOF

chmod +x renew_ssl.sh

# Agregar tarea cron para renovación (2 veces al mes)
echo "0 12 1,15 * * /efs/HELIPISTAS-ODOO-17/renew_ssl.sh >> /var/log/letsencrypt-renew.log 2>&1" | crontab -

echo "✅ Renovación automática configurada (1º y 15 de cada mes a las 12:00)"

# 9. VERIFICAR ESTADO
echo "=========================================="
echo "=== 9. VERIFICANDO SERVICIOS ==="
echo "=========================================="
echo "Esperando que los servicios se inicialicen..."
sleep 30
echo "Estado de los contenedores:"
/usr/local/bin/docker-compose ps

echo "=========================================="
echo "=== SETUP COMPLETADO EXITOSAMENTE ==="
echo "=========================================="
echo "Fecha finalización: $(date)"
echo "Odoo disponible en: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Nginx disponible en: https://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Certificado SSL: Let's Encrypt con renovación automática"
echo "Renovación programada: 1º y 15 de cada mes a las 12:00"
echo "=========================================="
