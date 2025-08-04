#!/bin/bash

# User Data Script para configurar EC2 instance con Docker y Odoo
# Este script se ejecuta automáticamente cuando la instancia se inicia

set -e

# Variables from Terraform
ODOO_MASTER_PASSWORD="${odoo_master_password}"
POSTGRES_PASSWORD="${postgres_password}"
DOMAIN_NAME="${domain_name}"
LETSENCRYPT_EMAIL="${letsencrypt_email}"
EFS_ID="${efs_id}"
EFS_MOUNT_POINT="${efs_mount_point}"

# Logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting user data script execution at $(date)"

# Update system
echo "Updating system packages..."
yum update -y

# Install Docker
echo "Installing Docker..."
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

# Install git and other utilities
echo "Installing additional packages..."
yum install -y git htop nano wget curl amazon-efs-utils

# Create directory structure
echo "Creating directory structure..."
mkdir -p /opt/odoo/{addons,config,data}
mkdir -p /opt/odoo/postgresql/data
mkdir -p /opt/odoo/nginx/{conf,ssl,logs}
mkdir -p /opt/odoo/backup

# Mount EFS if provided
if [ ! -z "$EFS_ID" ]; then
    echo "Mounting EFS file system: $EFS_ID at $EFS_MOUNT_POINT"
    
    # Create mount point
    mkdir -p "$EFS_MOUNT_POINT"
    
    # Mount EFS using EFS utils
    echo "$EFS_ID.efs.$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone).amazonaws.com:/ $EFS_MOUNT_POINT efs defaults,_netdev,tls" >> /etc/fstab
    
    # Mount now
    mount -a
    
    # Set permissions
    chown -R ec2-user:ec2-user "$EFS_MOUNT_POINT"
    
    echo "EFS mounted successfully at $EFS_MOUNT_POINT"
else
    echo "No EFS ID provided, skipping EFS mount"
fi

# Set permissions
chown -R ec2-user:ec2-user /opt/odoo

# Download Docker Compose file and configurations
echo "Setting up Odoo configuration..."
cd /opt/odoo

# Create docker-compose.yml
cat > docker-compose.yml << 'EOL'
version: '3.8'

services:
  postgresql:
    image: postgres:15
    container_name: odoo_postgresql
    restart: unless-stopped
    environment:
      POSTGRES_DB: odoo
      POSTGRES_USER: odoo
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      PGDATA: /var/lib/postgresql/data/pgdata
    volumes:
      - ./postgresql/data:/var/lib/postgresql/data/pgdata
      - ./backup:/backup
    networks:
      - odoo_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U odoo"]
      interval: 30s
      timeout: 10s
      retries: 5

  odoo:
    image: odoo:17
    container_name: odoo_app
    restart: unless-stopped
    depends_on:
      postgresql:
        condition: service_healthy
    environment:
      HOST: postgresql
      USER: odoo
      PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - ./addons:/mnt/extra-addons
      - ./config:/etc/odoo
      - ./data:/var/lib/odoo
    ports:
      - "127.0.0.1:8069:8069"
    networks:
      - odoo_network
    command: odoo --config=/etc/odoo/odoo.conf

  nginx:
    image: nginx:alpine
    container_name: odoo_nginx
    restart: unless-stopped
    depends_on:
      - odoo
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/conf/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - ./nginx/logs:/var/log/nginx
    networks:
      - odoo_network

networks:
  odoo_network:
    driver: bridge

volumes:
  postgresql_data:
  odoo_data:
EOL

# Create Odoo configuration file
cat > config/odoo.conf << EOL
[options]
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
admin_passwd = ${ODOO_MASTER_PASSWORD}
data_dir = /var/lib/odoo
db_host = postgresql
db_port = 5432
db_user = odoo
db_password = ${POSTGRES_PASSWORD}
db_maxconn = 64
db_template = template0
dbfilter = .*
debug_mode = False
email_from = False
limit_memory_hard = 2684354560
limit_memory_soft = 2147483648
limit_request = 8192
limit_time_cpu = 60
limit_time_real = 120
limit_time_real_cron = -1
list_db = True
log_db = False
log_db_level = warning
log_handler = :INFO
log_level = info
logfile = False
longpolling_port = 8072
max_cron_threads = 2
osv_memory_age_limit = False
osv_memory_count_limit = False
pg_path = None
pidfile = False
proxy_mode = True
reportgz = False
screencasts = None
screenshots = /tmp/odoo_tests
server_wide_modules = base,web
smtp_password = False
smtp_port = 587
smtp_server = localhost
smtp_ssl = False
smtp_user = False
syslog = False
test_enable = False
test_file = False
test_tags = None
translate_modules = ['all']
unaccent = False
without_demo = False
workers = 4
EOL

# Create nginx configuration
cat > nginx/conf/nginx.conf << 'EOL'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/javascript;

    include /etc/nginx/conf.d/*.conf;
}
EOL

# Create nginx default configuration
if [ -n "$DOMAIN_NAME" ]; then
    cat > nginx/conf/default.conf << EOL
# Upstream for Odoo
upstream odoo {
    server odoo:8069;
}

# HTTP redirect to HTTPS
server {
    listen 80;
    server_name $DOMAIN_NAME;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozTLS:10m;
    ssl_session_tickets off;

    # Modern configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # HSTS
    add_header Strict-Transport-Security "max-age=63072000" always;

    # Proxy settings
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Real-IP \$remote_addr;

    # Log files
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    # Main location
    location / {
        proxy_pass http://odoo;
        proxy_redirect off;
    }

    # Handle longpolling requests
    location /longpolling {
        proxy_pass http://odoo;
        proxy_redirect off;
    }

    # Cache static files
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }
}
EOL
else
    cat > nginx/conf/default.conf << 'EOL'
# Upstream for Odoo
upstream odoo {
    server odoo:8069;
}

# HTTP server
server {
    listen 80;
    server_name _;

    # Proxy settings
    proxy_read_timeout 720s;
    proxy_connect_timeout 720s;
    proxy_send_timeout 720s;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Real-IP $remote_addr;

    # Log files
    access_log /var/log/nginx/odoo.access.log;
    error_log /var/log/nginx/odoo.error.log;

    # Main location
    location / {
        proxy_pass http://odoo;
        proxy_redirect off;
    }

    # Handle longpolling requests
    location /longpolling {
        proxy_pass http://odoo;
        proxy_redirect off;
    }

    # Cache static files
    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://odoo;
    }
}
EOL
fi

# Set environment variables for docker-compose
echo "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}" > .env

# Change ownership
chown -R ec2-user:ec2-user /opt/odoo

# Start services
echo "Starting Docker services..."
cd /opt/odoo
/usr/local/bin/docker-compose up -d

# Install SSL certificates if domain is provided
if [ -n "$DOMAIN_NAME" ] && [ -n "$LETSENCRYPT_EMAIL" ]; then
    echo "Setting up SSL certificates..."
    
    # Wait for nginx to start
    sleep 30
    
    # Install certbot
    yum install -y certbot
    
    # Stop nginx temporarily
    docker-compose stop nginx
    
    # Get SSL certificate
    certbot certonly --standalone -d $DOMAIN_NAME --email $LETSENCRYPT_EMAIL --agree-tos --non-interactive
    
    # Copy certificates to nginx ssl directory
    cp /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem /opt/odoo/nginx/ssl/
    cp /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem /opt/odoo/nginx/ssl/
    
    # Set up auto-renewal
    echo "0 12 * * * /usr/bin/certbot renew --quiet && docker-compose -f /opt/odoo/docker-compose.yml restart nginx" | crontab -
    
    # Restart nginx with SSL
    docker-compose start nginx
fi

# Create backup script
cat > /opt/odoo/backup.sh << 'EOL'
#!/bin/bash
BACKUP_DIR="/opt/odoo/backup"
DATE=$(date +%Y%m%d_%H%M%S)
POSTGRES_PASSWORD="${postgres_password}"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Backup PostgreSQL database
docker exec odoo_postgresql pg_dump -U odoo -h localhost odoo | gzip > $BACKUP_DIR/odoo_db_$DATE.sql.gz

# Backup Odoo data directory
tar -czf $BACKUP_DIR/odoo_data_$DATE.tar.gz -C /opt/odoo data

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup completed: $DATE"
EOL

chmod +x /opt/odoo/backup.sh

# Set up daily backup cron job
echo "0 2 * * * /opt/odoo/backup.sh >> /var/log/odoo-backup.log 2>&1" | crontab -u ec2-user -

# Create status check script
cat > /opt/odoo/status.sh << 'EOL'
#!/bin/bash
echo "=== Odoo Services Status ==="
docker-compose -f /opt/odoo/docker-compose.yml ps
echo ""
echo "=== System Resources ==="
free -h
echo ""
df -h
echo ""
echo "=== Docker Resources ==="
docker stats --no-stream
EOL

chmod +x /opt/odoo/status.sh

echo "User data script completed successfully at $(date)"
echo "Odoo should be available at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) in a few minutes"
echo "Check status with: /opt/odoo/status.sh"
