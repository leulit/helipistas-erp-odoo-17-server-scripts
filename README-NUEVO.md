# 🚁 HELIPISTAS ERP - Odoo 17 Infrastructure

## 📋 **Resumen del Proyecto**

Sistema ERP completo basado en **Odoo 17** desplegado automáticamente en **AWS** con infraestructura como código usando **Terraform**. Diseñado para ser **completamente automático** - desde cero hasta funcionamiento completo con un solo comando.

### 🎯 **Características Principales**

- ✅ **Despliegue 100% Automático**: `terraform init && terraform apply`
- ✅ **SSL Automático**: Let's Encrypt con auto-renovación
- ✅ **Dominio**: https://erp17.helipistas.com
- ✅ **Persistencia**: EFS para datos permanentes
- ✅ **Optimizado**: Configuración de producción
- ✅ **Seguro**: Proxy Nginx, firewall configurado
- ✅ **Económico**: Uso de recursos AWS existentes

---

## 🏗️ **Arquitectura del Sistema**

### **Infraestructura AWS**
```
┌─────────────────────────────────────────────────┐
│                AWS Infrastructure                │
├─────────────────────────────────────────────────┤
│ • VPC: vpc-92d074f6 (existente)                │
│ • Subnet: subnet-a2d180e5 (existente)          │
│ • Elastic IP: eipalloc-0184418cc26d4e66f       │
│ • EFS: fs-ec7152d9 (persistencia)              │
│ • Security Group: puertos 22, 80, 443, 8069    │
│ • Key Pair: ERP (existente)                    │
└─────────────────────────────────────────────────┘
```

### **Stack de Aplicación**
```
┌─────────────────────────────────────────────────┐
│                Docker Stack                     │
├─────────────────────────────────────────────────┤
│ Nginx Proxy  │ ← SSL, Let's Encrypt             │
│     ↓        │   Domain: erp17.helipistas.com   │
│ Odoo 17      │ ← ERP Application                │
│     ↓        │   Workers: 2, optimizado         │
│ PostgreSQL15 │ ← Database                       │
│     ↓        │   Persistent storage             │
│ EFS Storage  │ ← /efs/HELIPISTAS-ODOO-17/       │
└─────────────────────────────────────────────────┘
```

---

## 🚀 **Despliegue Rápido**

### **Prerrequisitos**
```bash
# 1. AWS CLI configurado
aws configure list

# 2. Terraform instalado
terraform version

# 3. Archivo PEM
ls -la /Users/emiloalvarez/Work/PEMFiles/ERP.pem
```

### **Despliegue Completo (Un Solo Comando)**
```bash
# Navegar al directorio del proyecto
cd /Users/emiloalvarez/Work/PROYECTOS/HELIPISTAS/ODOO-17-2025/SERVER-SCRIPTS/terraform

# Ejecutar despliegue completo
terraform init && terraform apply -auto-approve
```

### **Proceso Automático (8-12 minutos)**
1. **🏗️ Infraestructura** (2-3 min): Crear EC2, Security Group, asociar IP
2. **📦 Sistema Base** (2-3 min): Amazon Linux, Docker, dependencias
3. **🐳 Servicios** (2-3 min): PostgreSQL, Odoo, Nginx
4. **🔒 SSL** (2-3 min): Let's Encrypt, configuración HTTPS
5. **✅ Verificación** (1 min): Health checks, logs

---

## 📁 **Estructura del Proyecto**

```
SERVER-SCRIPTS/
├── 📖 README.md                    # Esta documentación
├── 🔧 setup_odoo_complete.sh       # Script principal (GitHub)
├── 🏗️ user_data_simple.sh          # Bootstrap inicial
├── terraform/                      # Infraestructura
│   ├── main.tf                     # Recursos AWS
│   ├── variables.tf                # Variables configurables
│   ├── outputs.tf                  # IPs y URLs de salida
│   └── terraform.tfvars            # Configuración del proyecto
└── docker/                         # Configuración Docker (ref.)
    ├── docker-compose.yml          # Servicios
    ├── nginx/                      # Configuración Nginx
    └── odoo/                       # Configuración Odoo
```

### **Datos Persistentes en EFS**
```
/efs/HELIPISTAS-ODOO-17/
├── postgresql/                     # Base de datos
│   └── data/                       # Datos PostgreSQL
├── odoo/                          # Aplicación Odoo
│   ├── addons/                    # Módulos personalizados
│   ├── data/                      # Filestore y sesiones
│   └── conf/odoo.conf             # Configuración optimizada
├── nginx/                         # Proxy reverso
│   ├── conf/default.conf          # Configuración virtual host
│   └── ssl/                       # Certificados (no usado)
└── certbot/                       # Let's Encrypt
    ├── conf/                      # Certificados SSL
    └── www/                       # Validación ACME
```

---

## ⚙️ **Configuración**

### **Variables Principales (terraform.tfvars)**
```hcl
# Configuración del proyecto
project_name = "helipistas-odoo"
environment = "production"

# Dominio para SSL
domain_name = "erp17.helipistas.com"

# Contraseñas (cambiar en producción)
postgres_password = "your_secure_password_here"
odoo_master_password = "your_odoo_master_password_here"

# Recursos AWS existentes (no cambiar)
existing_elastic_ip_id = "eipalloc-0184418cc26d4e66f"
existing_efs_id = "fs-ec7152d9"
existing_vpc_id = "vpc-92d074f6"
existing_subnet_id = "subnet-a2d180e5"
existing_key_name = "ERP"
```

### **Configuración de Odoo (odoo.conf)**
```ini
[options]
# Database
db_host = postgresOdoo16
db_user = odoo
db_password = ${POSTGRES_PASSWORD}

# Performance
workers = 2
max_cron_threads = 1
limit_memory_hard = 1677721600
limit_memory_soft = 1342177280

# Proxy mode para Nginx
proxy_mode = True

# Paths
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
data_dir = /var/lib/odoo
```

---

## 🔧 **Gestión y Mantenimiento**

### **Verificar Estado del Sistema**
```bash
# Conectar al servidor
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Ver estado de contenedores
sudo docker ps -a

# Ver logs en tiempo real
sudo docker-compose -f /efs/HELIPISTAS-ODOO-17/docker-compose.yml logs -f

# Ver logs específicos
sudo docker logs helipistas_odoo -f
sudo docker logs helipistas_nginx -f
sudo docker logs postgresOdoo16 -f
```

### **Gestión de Servicios**
```bash
# Reiniciar servicios
cd /efs/HELIPISTAS-ODOO-17
sudo docker-compose restart

# Reiniciar servicio específico
sudo docker-compose restart helipistas_odoo
sudo docker-compose restart nginx

# Ver estado detallado
sudo docker-compose ps
```

### **Renovación SSL (Automática)**
```bash
# Ver certificados actuales
sudo docker exec helipistas_certbot ls -la /etc/letsencrypt/live/

# Renovar manualmente (si necesario)
cd /efs/HELIPISTAS-ODOO-17
sudo docker run --rm \
    -v "/efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot" \
    -v "/efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt" \
    certbot/certbot renew
sudo docker-compose restart nginx
```

---

## 🛠️ **Solución de Problemas**

### **Problemas Comunes**

#### **1. SSL No Funciona**
```bash
# Verificar certificados
sudo docker exec helipistas_nginx ls -la /etc/letsencrypt/live/erp17.helipistas.com/

# Verificar configuración Nginx
sudo docker exec helipistas_nginx cat /etc/nginx/conf.d/default.conf

# Regenerar certificados
cd /efs/HELIPISTAS-ODOO-17
sudo docker run --rm \
    -v "/efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot" \
    -v "/efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt" \
    certbot/certbot \
    certonly --webroot --webroot-path=/var/www/certbot \
    --email admin@helipistas.com --agree-tos --no-eff-email \
    --force-renewal --non-interactive \
    -d erp17.helipistas.com
```

#### **2. Odoo No Responde**
```bash
# Ver logs de Odoo
sudo docker logs helipistas_odoo --tail=50

# Verificar conexión a BD
sudo docker exec postgresOdoo16 psql -U odoo -d postgres -c "\l"

# Reiniciar Odoo
sudo docker-compose restart helipistas_odoo
```

#### **3. Base de Datos Corrupta**
```bash
# Backup de emergencia
sudo docker exec postgresOdoo16 pg_dumpall -U odoo > /efs/HELIPISTAS-ODOO-17/emergency_backup.sql

# Verificar integridad
sudo docker exec postgresOdoo16 psql -U odoo -d postgres -c "SELECT version();"
```

### **Logs Importantes**
```bash
# Cloud-init (setup inicial)
sudo tail -f /var/log/cloud-init-output.log

# Docker
sudo journalctl -u docker -f

# Sistema
sudo tail -f /var/log/messages
```

---

## 🔄 **Recrear Infraestructura**

### **Destruir y Recrear Completamente**
```bash
# ADVERTENCIA: Esto eliminará la instancia pero conservará datos en EFS
cd /Users/emiloalvarez/Work/PROYECTOS/HELIPISTAS/ODOO-17-2025/SERVER-SCRIPTS/terraform

# Destruir infraestructura
terraform destroy -auto-approve

# Recrear desde cero
terraform apply -auto-approve
```

### **Backup Antes de Destruir (Recomendado)**
```bash
# Conectar al servidor
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Backup completo
sudo docker exec postgresOdoo16 pg_dumpall -U odoo > /tmp/backup_$(date +%Y%m%d_%H%M%S).sql

# Descargar backup
scp -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152:/tmp/backup_*.sql ./
```

---

## 🔐 **Información de Seguridad**

### **Credenciales Importantes**
```bash
# Base de datos PostgreSQL
Usuario: odoo
Password: [configurado en terraform.tfvars]
Host: postgresOdoo16 (interno)

# Odoo Master Password
Password: [configurado en terraform.tfvars]
Uso: Gestión de bases de datos en /web/database

# SSH
Key: /Users/emiloalvarez/Work/PEMFiles/ERP.pem
Usuario: ec2-user
IP: 54.228.16.152 (Elastic IP)
```

### **Puertos Abiertos**
- **22**: SSH (acceso administrativo)
- **80**: HTTP (redirección a HTTPS)
- **443**: HTTPS (aplicación principal)
- **8069**: Odoo directo (solo para debug)

### **Cambiar Contraseñas**
```bash
# 1. Editar terraform.tfvars
vim terraform.tfvars

# 2. Aplicar cambios
terraform apply -auto-approve

# 3. El script actualizará automáticamente odoo.conf y variables de entorno
```

---

## 📊 **Monitoreo y Performance**

### **URLs de Acceso**
- **Aplicación Principal**: https://erp17.helipistas.com
- **Acceso Directo**: http://54.228.16.152:8069
- **Gestión BD**: https://erp17.helipistas.com/web/database

### **Métricas del Sistema**
```bash
# Uso de recursos
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152 "top -n1"

# Espacio en disco
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152 "df -h"

# Memoria de contenedores
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152 "sudo docker stats --no-stream"
```

---

## 🧹 **Mantenimiento**

### **Limpieza Periódica**
```bash
# Limpiar logs antiguos
sudo docker system prune -f

# Limpiar imágenes no usadas
sudo docker image prune -f

# Rotar logs de PostgreSQL
sudo docker exec postgresOdoo16 pg_ctl reload
```

### **Actualizaciones (Manual)**
```bash
# IMPORTANTE: Siempre hacer backup antes de actualizar
sudo docker exec postgresOdoo16 pg_dumpall -U odoo > /efs/HELIPISTAS-ODOO-17/backup_pre_update.sql

# Actualizar imágenes
cd /efs/HELIPISTAS-ODOO-17
sudo docker-compose pull
sudo docker-compose up -d
```

---

## 📝 **Notas de Desarrollo**

### **Scripts Clave**
1. **user_data_simple.sh**: Bootstrap inicial de la instancia EC2
2. **setup_odoo_complete.sh**: Setup completo alojado en GitHub
3. **Secuencia**: user_data → descarga setup_odoo_complete.sh → ejecuta setup completo

### **Flujo de Despliegue**
```
terraform apply
    ↓
user_data_simple.sh (EC2)
    ↓
download setup_odoo_complete.sh (GitHub)
    ↓
setup completo:
    ├── instalar Docker
    ├── crear directorios EFS
    ├── crear docker-compose.yml
    ├── crear odoo.conf
    ├── iniciar servicios base
    ├── obtener SSL con certbot
    ├── configurar Nginx HTTPS
    └── iniciar certbot auto-renewal
```

### **Modificaciones Futuras**
- Variables en `terraform.tfvars`
- Scripts en GitHub: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts
- Configuración Odoo en script (odoo.conf automático)

---

## 📞 **Soporte**

### **En Caso de Emergencia**
1. **Backup inmediato**: `pg_dumpall` + descargar
2. **Logs completos**: cloud-init + docker logs
3. **Recrear instancia**: `terraform destroy && terraform apply`
4. **Datos seguros**: EFS persiste todo

### **Repositorio del Proyecto**
- **GitHub**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts
- **Scripts**: setup_odoo_complete.sh actualizado automáticamente

---

## ✅ **Lista de Verificación Post-Despliegue**

- [ ] ✅ **Infraestructura**: terraform apply completado sin errores
- [ ] ✅ **Conectividad**: SSH funciona con clave PEM
- [ ] ✅ **Servicios**: todos los contenedores Docker corriendo
- [ ] ✅ **HTTP**: http://54.228.16.152:8069 responde
- [ ] ✅ **HTTPS**: https://erp17.helipistas.com funciona
- [ ] ✅ **SSL**: certificado válido de Let's Encrypt
- [ ] ✅ **Base de Datos**: conexión PostgreSQL funcional
- [ ] ✅ **Odoo**: interfaz accesible y funcional
- [ ] ✅ **Persistencia**: datos almacenados en EFS
- [ ] ✅ **Auto-renovación**: certbot configurado

---

**🎯 Este proyecto está listo para producción y proporciona un ERP Odoo 17 completo, seguro y automático en AWS.**
