# 🔧 Guía para Desarrolladores - Helipistas Odoo 17

## 📋 Índice

1. [Arquitectura Técnica](#arquitectura-técnica)
2. [Flujo de Deployment](#flujo-de-deployment)
3. [Modificar Configuraciones](#modificar-configuraciones)
4. [Agregar Funcionalidades](#agregar-funcionalidades)
5. [Debugging y Logs](#debugging-y-logs)
6. [Testing](#testing)
7. [Best Practices](#best-practices)

---

## 🏗️ Arquitectura Técnica

### Stack Tecnológico

```
┌─────────────────────────────────────────────┐
│          Infrastructure Layer                │
│  ┌──────────────────────────────────────┐   │
│  │ Terraform (IaC)                      │   │
│  │ - Gestión de recursos AWS            │   │
│  │ - Estado en local (terraform.tfstate)│   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│           AWS Resources Layer                │
│  ┌──────────────────────────────────────┐   │
│  │ EC2 Instance (Amazon Linux 2)        │   │
│  │ EFS (Persistent Storage)             │   │
│  │ Elastic IP (Static Public IP)        │   │
│  │ Security Group (Firewall)            │   │
│  │ VPC & Subnet (Networking)            │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│         Initialization Layer                 │
│  ┌──────────────────────────────────────┐   │
│  │ user_data_simple.sh                  │   │
│  │ - Install system dependencies        │   │
│  │ - Mount EFS                          │   │
│  │ - Download setup_odoo_complete.sh    │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│         Configuration Layer                  │
│  ┌──────────────────────────────────────┐   │
│  │ setup_odoo_complete.sh (GitHub)      │   │
│  │ - Create docker-compose.yml          │   │
│  │ - Create nginx config                │   │
│  │ - Create odoo.conf                   │   │
│  │ - Obtain SSL certificate             │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────┐
│          Application Layer                   │
│  ┌──────────────────────────────────────┐   │
│  │ Docker Containers:                   │   │
│  │  - PostgreSQL 15                     │   │
│  │  - Odoo 17                           │   │
│  │  - Nginx (Reverse Proxy)             │   │
│  │  - Certbot (SSL Management)          │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

### Componentes Clave

#### 1. Terraform Configuration

**Archivos**:
- `main.tf`: Definición de recursos AWS
- `variables.tf`: Variables de entrada
- `outputs.tf`: Outputs del deployment
- `terraform.tfvars`: Valores de configuración (gitignored)

**Recursos gestionados**:
- `aws_security_group.main`: Firewall de red
- `aws_instance.main`: Instancia EC2
- `aws_eip_association.main`: Asociación de Elastic IP

**Recursos referenciados** (no gestionados):
- `data.aws_vpc.main`: VPC existente
- `data.aws_subnet.public`: Subnet existente
- `data.aws_ami.amazon_linux`: AMI de Amazon Linux 2

#### 2. User Data Script

**Archivo**: `terraform/user_data_simple.sh`

**Responsabilidades**:
1. Instalar dependencias del sistema
2. Configurar Docker
3. Montar EFS
4. Crear estructura de directorios
5. Descargar y ejecutar setup completo

**Template variables**:
```bash
POSTGRES_PASSWORD="${POSTGRES_PASSWORD}"
ODOO_MASTER_PASSWORD="${ODOO_MASTER_PASSWORD}"
EFS_ID="${EFS_ID}"
ELASTIC_IP_ID="${ELASTIC_IP_ID}"
DOMAIN_NAME="${DOMAIN_NAME}"
```

#### 3. Setup Complete Script

**Archivo**: `setup_odoo_complete.sh` (en GitHub)

**Secciones**:
1. Corrección de permisos
2. Creación de docker-compose.yml
3. Configuración de Nginx (HTTP)
4. Creación de odoo.conf
5. Inicio de servicios básicos
6. Obtención de certificado SSL
7. Reconfiguración de Nginx (HTTPS)
8. Inicio de servicio certbot

**Parámetros**:
```bash
./setup_odoo_complete.sh <postgres_password> <odoo_master_password> <domain_name>
```

---

## 🔄 Flujo de Deployment

### Secuencia Completa

```
[terraform apply]
        │
        ├─► 1. Terraform lee variables de terraform.tfvars
        │
        ├─► 2. Terraform crea Security Group
        │      └─► Puertos: 22, 80, 443, 8069, 2049
        │
        ├─► 3. Terraform lanza EC2 Instance
        │      ├─► AMI: Amazon Linux 2 (latest)
        │      ├─► Type: t3.medium
        │      ├─► User Data: user_data_simple.sh (templated)
        │      └─► Tags: Name=HELIPISTAS-ODOO-17-INSTANCE
        │
        ├─► 4. Terraform asocia Elastic IP
        │      └─► IP: 54.228.16.152
        │
        └─► 5. EC2 ejecuta user_data_simple.sh
               │
               ├─► 5.1. Actualizar sistema (yum update)
               │
               ├─► 5.2. Instalar dependencias
               │      ├─► Docker
               │      ├─► Docker Compose
               │      ├─► AWS CLI
               │      └─► NFS Utils (amazon-efs-utils)
               │
               ├─► 5.3. Montar EFS
               │      └─► mount -t nfs4 fs-ec7152d9.efs.eu-west-1.amazonaws.com:/ /efs
               │
               ├─► 5.4. Crear directorios
               │      └─► /efs/HELIPISTAS-ODOO-17/{postgres,odoo,nginx,certbot}
               │
               └─► 5.5. Descargar y ejecutar setup_odoo_complete.sh
                      │
                      ├─► 5.5.1. Corregir permisos
                      │      ├─► chown 101:101 odoo/
                      │      ├─► chown 999:999 postgres/
                      │      └─► chmod 755 directorios
                      │
                      ├─► 5.5.2. Crear docker-compose.yml
                      │      ├─► PostgreSQL service
                      │      ├─► Odoo service
                      │      ├─► Nginx service
                      │      └─► Certbot service
                      │
                      ├─► 5.5.3. Crear nginx/conf/default.conf (HTTP)
                      │      ├─► Listen 80
                      │      ├─► Proxy pass a Odoo
                      │      └─► ACME challenge support
                      │
                      ├─► 5.5.4. Crear odoo/conf/odoo.conf
                      │      ├─► Database config
                      │      ├─► Workers config
                      │      ├─► Proxy mode = True
                      │      └─► Paths config
                      │
                      ├─► 5.5.5. Iniciar servicios básicos
                      │      ├─► docker-compose up -d postgresOdoo16
                      │      ├─► docker-compose up -d helipistas_odoo
                      │      ├─► docker-compose up -d nginx
                      │      └─► sleep 45 (esperar inicialización)
                      │
                      ├─► 5.5.6. Obtener certificado SSL
                      │      └─► docker run certbot/certbot certonly
                      │          ├─► --webroot-path=/var/www/certbot
                      │          ├─► --force-renewal
                      │          ├─► --non-interactive
                      │          └─► -d erp17.helipistas.com
                      │
                      ├─► 5.5.7. Reconfigurar Nginx (HTTPS)
                      │      ├─► HTTP: redirect to HTTPS
                      │      ├─► HTTPS: listen 443 ssl
                      │      ├─► SSL cert: /etc/letsencrypt/live/erp17.helipistas.com/
                      │      └─► Proxy pass a Odoo
                      │
                      ├─► 5.5.8. Reiniciar Nginx
                      │      └─► docker-compose restart nginx
                      │
                      └─► 5.5.9. Iniciar certbot (auto-renewal)
                             └─► docker-compose up -d certbot

[✅ DEPLOYMENT COMPLETO]
```

### Timing Estimado

| Fase | Duración | Descripción |
|------|----------|-------------|
| Terraform Apply | 2-3 min | Creación de recursos AWS |
| System Update | 1-2 min | yum update |
| Install Dependencies | 1-2 min | Docker, AWS CLI, etc. |
| Mount EFS | 10-20 seg | NFS mount |
| Setup Docker | 1-2 min | Crear configs y docker-compose |
| Start Services | 1-2 min | Iniciar PostgreSQL, Odoo, Nginx |
| SSL Certificate | 1-2 min | Obtener certificado Let's Encrypt |
| Final Config | 30 seg | Reconfigurar Nginx y reiniciar |
| **TOTAL** | **10-12 min** | **Deployment completo** |

---

## 🔨 Modificar Configuraciones

### Cambiar Configuración de Odoo

**Archivo a modificar**: `setup_odoo_complete.sh` (sección 5)

```bash
# Buscar la sección que crea odoo.conf
cat > /efs/HELIPISTAS-ODOO-17/odoo/conf/odoo.conf << EOF
[options]
# MODIFICAR AQUÍ
workers = 4  # Ejemplo: aumentar workers para mayor carga
max_cron_threads = 2  # Ejemplo: más threads para cron jobs

# Agregar nuevas configuraciones
log_level = debug  # Para debugging
limit_time_real_cron = 300  # Timeout para cron jobs
EOF
```

**Proceso**:
1. Modificar `setup_odoo_complete.sh` en el repositorio
2. Commit y push a GitHub
3. Ejecutar `terraform destroy && terraform apply`
4. El nuevo script se descarga automáticamente

### Cambiar Configuración de Nginx

**Archivo a modificar**: `setup_odoo_complete.sh` (secciones 6 y 9)

**Ejemplo: Agregar headers de seguridad**:

```bash
# Sección 9 (HTTPS configuration)
cat > nginx/conf/default.conf << EOF
server {
    listen 443 ssl http2;
    server_name $DOMAIN_NAME;

    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # NUEVOS HEADERS DE SEGURIDAD
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Proxy to Odoo
    location / {
        proxy_pass http://helipistas_odoo:8069;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF
```

### Cambiar Versión de PostgreSQL o Odoo

**Archivo a modificar**: `setup_odoo_complete.sh` (sección 2)

```bash
# Cambiar versión de PostgreSQL
postgresOdoo16:
  image: postgres:16  # Cambiar de 15 a 16

# Cambiar versión de Odoo
helipistas_odoo:
  image: odoo:18.0  # Cambiar de 17 a 18
```

⚠️ **ADVERTENCIA**: 
- Cambiar versiones requiere migraciones de base de datos
- Hacer backup antes de cambiar versiones
- Probar en ambiente de desarrollo primero

### Agregar Variable de Entorno

**1. Agregar en `variables.tf`**:

```hcl
variable "nueva_variable" {
  description = "Descripción de la variable"
  type        = string
  default     = "valor_por_defecto"
}
```

**2. Agregar en `terraform.tfvars`**:

```hcl
nueva_variable = "valor_personalizado"
```

**3. Usar en `user_data_simple.sh`**:

```bash
# Template variable
NUEVA_VARIABLE="${NUEVA_VARIABLE}"

# Usar en el script
echo "Valor de nueva variable: $NUEVA_VARIABLE"
```

**4. Pasar a `setup_odoo_complete.sh`**:

```bash
# En user_data_simple.sh
./setup_odoo_complete.sh "$POSTGRES_PASSWORD" "$ODOO_MASTER_PASSWORD" "$DOMAIN_NAME" "$NUEVA_VARIABLE"

# En setup_odoo_complete.sh
NUEVA_VARIABLE="$4"
```

---

## 🆕 Agregar Funcionalidades

### Agregar Nuevo Contenedor Docker

**Ejemplo: Agregar Redis para cache**

**1. Modificar docker-compose.yml en `setup_odoo_complete.sh`**:

```bash
cat > docker-compose.yml << EOF
version: '3.8'
services:
  # ... servicios existentes ...

  redis:
    image: redis:7-alpine
    container_name: helipistas_redis
    ports:
      - "6379:6379"
    volumes:
      - /efs/HELIPISTAS-ODOO-17/redis:/data
    command: redis-server --appendonly yes
    restart: unless-stopped
    networks:
      - helipistas_network
EOF
```

**2. Crear directorio para Redis**:

```bash
# En user_data_simple.sh, agregar:
mkdir -p "$PROJECT_DIR"/redis
chown -R ec2-user:ec2-user "$PROJECT_DIR"/redis
```

**3. Configurar Odoo para usar Redis** (si aplicable):

```bash
# En odoo.conf
[options]
# ... configuración existente ...
session_store = redis
session_redis_host = redis
session_redis_port = 6379
```

### Agregar Módulo Custom de Odoo

**Opción 1: Durante el deployment**

```bash
# En setup_odoo_complete.sh, después de crear directorios:
echo "Descargando módulos custom..."
git clone https://github.com/usuario/odoo-custom-modules.git /efs/HELIPISTAS-ODOO-17/odoo/addons/custom
chown -R 101:101 /efs/HELIPISTAS-ODOO-17/odoo/addons/custom
```

**Opción 2: Después del deployment**

```bash
# Conectarse al servidor
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Clonar módulos
sudo git clone https://github.com/usuario/odoo-custom-modules.git /efs/HELIPISTAS-ODOO-17/odoo/addons/custom

# Corregir permisos
sudo chown -R 101:101 /efs/HELIPISTAS-ODOO-17/odoo/addons/custom

# Reiniciar Odoo
cd /efs/HELIPISTAS-ODOO-17
docker-compose restart helipistas_odoo

# Actualizar lista de módulos en Odoo UI
# Apps > Update Apps List
```

### Agregar Backup Automático

**1. Crear script de backup en setup_odoo_complete.sh**:

```bash
# Crear script de backup
cat > /opt/backup_odoo.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/efs/HELIPISTAS-ODOO-17/backups"
mkdir -p $BACKUP_DIR

# Backup de PostgreSQL
docker exec helipistas_postgres pg_dumpall -U odoo | gzip > $BACKUP_DIR/postgres_$(date +%Y%m%d_%H%M%S).sql.gz

# Backup de archivos de Odoo
tar -czf $BACKUP_DIR/odoo_files_$(date +%Y%m%d_%H%M%S).tar.gz -C /efs/HELIPISTAS-ODOO-17/odoo filestore/

# Eliminar backups antiguos (más de 7 días)
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete
EOF

chmod +x /opt/backup_odoo.sh
```

**2. Agregar cron job**:

```bash
# Agregar a crontab
echo "0 2 * * * /opt/backup_odoo.sh" | crontab -
```

---

## 🐛 Debugging y Logs

### Niveles de Logs

```
1. Cloud-Init Logs (Inicial)
   └─► /var/log/cloud-init-output.log
       └─► Muestra: instalación de dependencias, montaje EFS

2. Setup Complete Logs
   └─► /var/log/odoo-setup-complete.log
       └─► Muestra: creación de configs, inicio de servicios, SSL

3. Docker Logs
   ├─► docker logs helipistas_odoo
   │   └─► Logs de aplicación Odoo
   ├─► docker logs helipistas_postgres
   │   └─► Logs de PostgreSQL
   ├─► docker logs helipistas_nginx
   │   └─► Logs de Nginx (access + error)
   └─► docker logs helipistas_certbot
       └─► Logs de obtención/renovación SSL

4. System Logs
   └─► journalctl -f
       └─► Logs del sistema completo
```

### Ver Logs en Tiempo Real

```bash
# Todos los logs de cloud-init
sudo tail -f /var/log/cloud-init-output.log

# Solo errores de cloud-init
sudo grep -i error /var/log/cloud-init-output.log

# Logs del setup completo
sudo tail -f /var/log/odoo-setup-complete.log

# Logs de Docker Compose
cd /efs/HELIPISTAS-ODOO-17
docker-compose logs -f

# Logs de un servicio específico
docker-compose logs -f helipistas_odoo --tail=100

# Logs con timestamp
docker-compose logs -f --timestamps
```

### Debugging de Problemas Comunes

#### Problema: Odoo no arranca

```bash
# 1. Ver logs de Odoo
docker logs helipistas_odoo --tail=50

# 2. Verificar que PostgreSQL está listo
docker exec helipistas_postgres pg_isready -U odoo

# 3. Verificar configuración de Odoo
cat /efs/HELIPISTAS-ODOO-17/odoo/conf/odoo.conf

# 4. Verificar permisos
ls -la /efs/HELIPISTAS-ODOO-17/odoo/

# 5. Intentar arrancar manualmente con más verbosidad
docker exec -it helipistas_odoo odoo --log-level=debug
```

#### Problema: SSL no se obtiene

```bash
# 1. Ver logs de certbot
docker logs helipistas_certbot

# 2. Verificar DNS
nslookup erp17.helipistas.com

# 3. Verificar que Nginx está escuchando en puerto 80
sudo netstat -tlnp | grep :80

# 4. Verificar configuración de Nginx
cat /efs/HELIPISTAS-ODOO-17/nginx/conf/default.conf

# 5. Probar obtener certificado manualmente con verbose
docker run --rm --name certbot-debug \
  -v "/efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot" \
  -v "/efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt" \
  certbot/certbot \
  certonly --webroot --webroot-path=/var/www/certbot \
  --email admin@helipistas.com --agree-tos --no-eff-email \
  --force-renewal --non-interactive -v \
  -d erp17.helipistas.com
```

#### Problema: Alto consumo de recursos

```bash
# 1. Ver consumo en tiempo real
docker stats

# 2. Ver procesos dentro de contenedores
docker exec helipistas_odoo top

# 3. Ver espacio en disco
df -h

# 4. Ver espacio usado por Docker
docker system df

# 5. Ver logs de PostgreSQL para queries lentas
docker logs helipistas_postgres | grep "duration:"

# 6. Optimizar base de datos
docker exec helipistas_postgres vacuumdb -U odoo --all --analyze
```

---

## 🧪 Testing

### Testing de Deployment

**1. Test en Ambiente Aislado**:

```bash
# Modificar terraform.tfvars para usar recursos diferentes
resource_prefix = "PRUEBAS-ODOO-17"

# Desplegar
terraform apply

# Probar
curl -I https://erp17.helipistas.com

# Destruir
terraform destroy
```

**2. Test de Scripts Modificados**:

```bash
# 1. Crear branch de pruebas en GitHub
git checkout -b feature/nueva-funcionalidad

# 2. Modificar setup_odoo_complete.sh

# 3. Subir a GitHub
git add setup_odoo_complete.sh
git commit -m "Nueva funcionalidad"
git push origin feature/nueva-funcionalidad

# 4. Modificar user_data_simple.sh para descargar desde el branch
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/feature/nueva-funcionalidad/setup_odoo_complete.sh

# 5. Desplegar y probar
terraform apply

# 6. Si funciona, mergear a main
git checkout main
git merge feature/nueva-funcionalidad
git push origin main
```

### Verificación Post-Deployment

**Checklist de verificación**:

```bash
# ✅ 1. Instancia EC2 está corriendo
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)

# ✅ 2. EFS está montado
ssh -i ~/.ssh/ERP.pem ec2-user@54.228.16.152 "df -h | grep efs"

# ✅ 3. Contenedores están corriendo
ssh -i ~/.ssh/ERP.pem ec2-user@54.228.16.152 "cd /efs/HELIPISTAS-ODOO-17 && docker-compose ps"

# ✅ 4. PostgreSQL responde
ssh -i ~/.ssh/ERP.pem ec2-user@54.228.16.152 "docker exec helipistas_postgres pg_isready -U odoo"

# ✅ 5. Odoo responde
curl -I http://54.228.16.152:8069

# ✅ 6. Nginx responde
curl -I http://54.228.16.152

# ✅ 7. SSL está configurado
curl -I https://erp17.helipistas.com

# ✅ 8. Certificado es válido
openssl s_client -connect erp17.helipistas.com:443 -servername erp17.helipistas.com < /dev/null 2>/dev/null | openssl x509 -noout -dates

# ✅ 9. DNS resuelve correctamente
nslookup erp17.helipistas.com
```

---

## 📏 Best Practices

### Seguridad

1. **Nunca subir terraform.tfvars a Git**
   - Contiene contraseñas sensibles
   - Usar `.gitignore` para excluirlo

2. **Usar contraseñas fuertes**
   ```bash
   # Generar contraseña segura
   openssl rand -base64 32
   ```

3. **Limitar acceso SSH a IPs específicas** (opcional)
   ```hcl
   # En main.tf, modificar Security Group
   ingress {
     from_port   = 22
     to_port     = 22
     protocol    = "tcp"
     cidr_blocks = ["TU_IP/32"]  # Solo tu IP
   }
   ```

4. **Mantener certificados SSL actualizados**
   - Certbot renueva automáticamente
   - Verificar periódicamente: `docker logs helipistas_certbot`

### Mantenimiento

1. **Backups regulares**
   - Base de datos: `pg_dumpall`
   - Archivos: `tar -czf`
   - Subir a S3 para redundancia

2. **Monitoreo de recursos**
   ```bash
   # Ver consumo periódicamente
   docker stats --no-stream
   df -h
   ```

3. **Actualizar imágenes Docker**
   ```bash
   # Actualizar a versiones específicas, no latest
   image: postgres:15.4  # En lugar de postgres:15
   image: odoo:17.0      # En lugar de odoo:17
   ```

4. **Logs rotation**
   - Configurar logrotate para evitar que logs llenen el disco

### Desarrollo

1. **Usar branches para nuevas features**
   ```bash
   git checkout -b feature/nombre
   # desarrollar
   git push origin feature/nombre
   # crear PR
   ```

2. **Documentar cambios**
   - README.md para cambios de arquitectura
   - Comentarios en código para lógica compleja
   - CHANGELOG.md para versiones

3. **Testing antes de mergear a main**
   - Probar en ambiente aislado
   - Verificar que no rompe funcionalidad existente

4. **Versionado semántico**
   - MAJOR: cambios incompatibles
   - MINOR: nuevas funcionalidades compatibles
   - PATCH: bug fixes

### Terraform

1. **Usar terraform fmt**
   ```bash
   terraform fmt -recursive
   ```

2. **Validar antes de aplicar**
   ```bash
   terraform validate
   terraform plan
   ```

3. **Estado de Terraform**
   - Backup del archivo `terraform.tfstate`
   - Considerar remote state (S3 + DynamoDB) para equipos

4. **Recursos existentes**
   - No gestionar recursos que ya existen (EFS, VPC, Elastic IP)
   - Usar `data sources` para referenciarlos

---

## 📚 Referencias

### Documentación Oficial

- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Docker Compose**: https://docs.docker.com/compose/
- **Odoo 17**: https://www.odoo.com/documentation/17.0/
- **PostgreSQL 15**: https://www.postgresql.org/docs/15/
- **Nginx**: https://nginx.org/en/docs/
- **Let's Encrypt**: https://letsencrypt.org/docs/

### Herramientas Útiles

- **AWS CLI**: https://aws.amazon.com/cli/
- **Docker CLI**: https://docs.docker.com/engine/reference/commandline/cli/
- **Certbot**: https://certbot.eff.org/docs/

### Ejemplos de Código

- **Terraform AWS Examples**: https://github.com/terraform-aws-modules
- **Docker Compose Examples**: https://github.com/docker/awesome-compose
- **Odoo Docker**: https://hub.docker.com/_/odoo

---

## 🤝 Contribuir

### Workflow de Contribución

1. Fork el repositorio
2. Crear branch: `git checkout -b feature/nueva-funcionalidad`
3. Hacer cambios y commit: `git commit -am 'Agregar nueva funcionalidad'`
4. Push al branch: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request en GitHub

### Guidelines

- Seguir estilo de código existente
- Documentar cambios en README.md
- Agregar comentarios explicativos
- Probar antes de crear PR
- Incluir descripción detallada en PR

---

**Esta guía cubre los aspectos técnicos principales para desarrollar y mantener el proyecto Helipistas Odoo 17. Para uso general, consultar el README.md principal.** 🚀
