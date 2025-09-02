# 🚀 **Guía Completa de Despliegue - Helipistas ERP Odoo 17**

[![AWS](https://img.shields.io/badge/AWS-EC2%20Spot-orange)](https://aws.amazon.com)
[![Terraform](https://img.shields.io/badge/Terraform-Infrastructure-blue)](https://terraform.io)
[![Docker](https://img.shields.io/badge/Docker-Containers-blue)](https://docker.com)
[![Odoo](https://img.shields.io/badge/Odoo-17-purple)](https://odoo.com)

## **📋 Análisis del Proyecto**

### **🏗️ Arquitectura Completa**

```
┌─────────────────────────────────────────────────────────┐
│                     AWS CLOUD                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────┐ │
│  │   Elastic IP    │  │   EC2 Spot      │  │   EFS   │ │
│  │   (Estática)    │→ │   t3.medium     │←→│(Opcional)│ │
│  └─────────────────┘  │                 │  └─────────┘ │
│                       │  ┌───────────┐  │              │
│                       │  │   Docker  │  │              │
│                       │  │ ┌───────┐ │  │              │
│                       │  │ │ Nginx │ │  │              │
│                       │  │ │ Proxy │ │  │              │
│                       │  │ └───────┘ │  │              │
│                       │  │ ┌───────┐ │  │              │
│                       │  │ │ Odoo  │ │  │              │
│                       │  │ │  17   │ │  │              │
│                       │  │ └───────┘ │  │              │
│                       │  │ ┌───────┐ │  │              │
│                       │  │ │Postgre│ │  │              │
│                       │  │ │SQL 15 │ │  │              │
│                       │  │ └───────┘ │  │              │
│                       │  └───────────┘  │              │
│                       └─────────────────┘              │
└─────────────────────────────────────────────────────────┘
```

### **✅ Componentes Incluidos**

- **🏗️ Infraestructura AWS** (Terraform)
  - VPC privada con subnet pública
  - EC2 Spot Instance (60-90% más barato)
  - Security Groups optimizados
  - Elastic IP estática
  - EFS opcional para persistencia

- **🐳 Stack Docker Optimizado**
  - **Nginx**: Proxy reverso con SSL y caché
  - **Odoo 17**: Configuración optimizada para producción
  - **PostgreSQL 15**: Base de datos con tuning avanzado
  - **Health checks** y auto-restart automático

- **🛠️ Scripts de Automatización**
  - `deploy.sh`: Despliegue automático completo
  - `manage.sh`: Gestión y mantenimiento
  - `backup.sh`: Backups automáticos a S3
  - `monitor.sh`: Monitoreo y alertas

## **🔧 Prerequisites**

### **1. Software Requerido**

```bash
# Verificar que tienes instalado:
terraform --version   # Terraform >= 1.0
aws --version        # AWS CLI v2
git --version        # Git
```

**Instalar si falta:**
```bash
# Terraform
# macOS: brew install terraform
# Linux: wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip

# AWS CLI v2
# macOS: brew install awscli
# Linux: curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

### **2. Configuración AWS**

```bash
# Configurar credenciales AWS
aws configure

# Introducir:
# AWS Access Key ID: [tu-access-key]
# AWS Secret Access Key: [tu-secret-key]  
# Default region name: eu-west-1
# Default output format: json

# Verificar configuración
aws sts get-caller-identity
```

### **3. Key Pair de AWS**

```bash
# Verificar tus Key Pairs existentes
aws ec2 describe-key-pairs --region eu-west-1

# O desde la consola web:
# AWS Console → EC2 → Key Pairs → Ver nombre de tu clave
# Ejemplo: si tienes "mi-clave.pem", el nombre es "mi-clave"
```

## **⚙️ Configuración del Proyecto**

### **Tu Configuración Actual**

El proyecto está preconfigurado con tus valores:

```hcl
# terraform/terraform.tfvars
aws_region = "eu-west-1a"              # ✅ Tu región Europa
project_name = "helipistas-odoo"       # ✅ Tu proyecto
environment = "HLP-ERP-ODOO-17"        # ✅ Tu entorno
odoo_master_password = "helipistas@2025"   # ✅ Tu contraseña Odoo
postgres_password = "helipistas@2025"      # ✅ Tu contraseña BD
```

### **📝 Solo Necesitas Cambiar**

```bash
# Editar el archivo de configuración
nano terraform/terraform.tfvars

# ÚNICA línea que debes cambiar:
key_pair_name = "tu-key-pair-real-de-aws"  # ← Cambiar por tu Key Pair real
```

**Ejemplo:**
```hcl
# Si tu archivo se llama "helipistas-key.pem"
key_pair_name = "helipistas-key"

# Si tu archivo se llama "aws-main.pem"  
key_pair_name = "aws-main"
```

## **🚀 Proceso de Despliegue**

### **Opción A: Despliegue Automático (Recomendado)**

```bash
# 1. Verificar que todo está listo
./deploy.sh --check

# 2. Despliegue completo automático
./deploy.sh

# 🕐 Tiempo total: 5-10 minutos
# ✅ Al final tendrás tu servidor Odoo funcionando
```

**Lo que hace automáticamente:**
1. ✅ Verifica prerequisites
2. ✅ Valida configuración
3. ✅ Crea infraestructura AWS
4. ✅ Instala Docker en EC2
5. ✅ Descarga y configura Odoo
6. ✅ Configura base de datos PostgreSQL
7. ✅ Configura proxy Nginx
8. ✅ Inicia todos los servicios
9. ✅ Genera información de acceso

### **Opción B: Despliegue Manual (Paso a Paso)**

```bash
# 1. Inicializar Terraform
cd terraform
terraform init

# 2. Ver qué se va a crear
terraform plan

# 3. Crear infraestructura
terraform apply
# Responder: yes

# 4. Obtener IP del servidor
terraform output instance_public_ip

# 5. Esperar instalación automática (5-10 min)
# El servidor se auto-configura solo

# 6. Verificar estado
cd ..
./manage.sh status
```

## **📊 Información de Despliegue**

### **Datos de Tu Configuración**

```bash
# Después del despliegue verás:
╔════════════════════════════════════════════════════════════════════╗
║                    🚀 DESPLIEGUE COMPLETADO                       ║
╠════════════════════════════════════════════════════════════════════╣
║ 📊 Proyecto: helipistas-odoo                                      ║
║ 🌍 Región: eu-west-1a                                             ║
║ 💻 Instancia: t3.medium (Spot Instance)                           ║
║ 🔗 IP Pública: X.X.X.X                                            ║
║ 🌐 URL Odoo: http://X.X.X.X                                       ║
║ 🔑 SSH: ssh -i ~/.ssh/tu-clave.pem ec2-user@X.X.X.X               ║
║ 🗄️ Base de datos: PostgreSQL 15                                   ║
║ 🔐 Contraseñas: helipistas@2025                                   ║
╚════════════════════════════════════════════════════════════════════╝
```

## **✅ Verificación Post-Despliegue**

### **1. Verificar Estado del Sistema**

```bash
# Estado completo de servicios
./manage.sh status

# Output esperado:
# ✅ Instancia EC2: Ejecutándose
# ✅ Docker: Activo
# ✅ Nginx: Funcionando (Puerto 80)
# ✅ Odoo: Funcionando (Puerto 8069)
# ✅ PostgreSQL: Funcionando (Puerto 5432)
```

### **2. Verificar Acceso Web**

```bash
# Obtener URL de acceso
./manage.sh info

# Abrir en navegador:
open http://IP-DE-TU-SERVIDOR
```

### **3. Verificar Logs**

```bash
# Ver logs en tiempo real
./manage.sh logs

# Ver logs específicos
./manage.sh logs odoo      # Solo Odoo
./manage.sh logs nginx     # Solo Nginx
./manage.sh logs postgres  # Solo PostgreSQL
```

## **🔧 Primera Configuración de Odoo**

### **Paso 1: Acceder a la Interfaz Web**

1. Abrir navegador en: `http://IP-DE-TU-SERVIDOR`
2. Verás la pantalla de configuración inicial de Odoo

### **Paso 2: Crear Base de Datos**

```
🗄️ Configuración de Base de Datos Recomendada:
┌─────────────────────────────────────────────────┐
│ Database Name: helipistas_erp                   │
│ Email: admin@helipistas.com                     │
│ Password: helipistas@2025                       │
│ Phone: +34 XXX XXX XXX (opcional)              │
│ Language: Español                               │
│ Country: España                                 │
│ Demo data: ❌ No (para producción)              │
└─────────────────────────────────────────────────┘
```

### **Paso 3: Módulos Recomendados**

Para un ERP completo, instalar:
- ✅ **Contabilidad**: Facturación y contabilidad
- ✅ **Ventas**: Gestión de ventas y CRM
- ✅ **Compras**: Gestión de proveedores
- ✅ **Inventario**: Control de stock
- ✅ **Proyecto**: Gestión de proyectos
- ✅ **RRHH**: Recursos humanos (opcional)

## **🛠️ Gestión del Servidor**

### **Comandos Principales**

```bash
# 📊 Estado y monitoreo
./manage.sh status          # Estado completo del sistema
./manage.sh monitor         # Recursos en tiempo real (CPU, RAM, disco)
./manage.sh costs           # Costos AWS actuales
./manage.sh info            # Información de conexión

# 🔄 Control de servicios
./manage.sh restart         # Reiniciar todos los servicios
./manage.sh stop            # Parar servicios
./manage.sh start           # Iniciar servicios
./manage.sh update          # Actualizar contenedores

# 📋 Logs y debugging
./manage.sh logs            # Logs de todos los servicios
./manage.sh logs odoo       # Solo logs de Odoo
./manage.sh logs -f         # Seguir logs en tiempo real

# 🔗 Acceso remoto
./manage.sh ssh             # Conectar por SSH
./manage.sh remote "comando" # Ejecutar comando remoto
```

### **Comandos de Backup y Restauración**

```bash
# 💾 Backups
./manage.sh backup                    # Backup completo
./manage.sh backup --upload-s3        # Backup y subir a S3
./manage.sh list-backups              # Listar backups disponibles
./manage.sh download-backup archivo   # Descargar backup específico

# 🔄 Restauración
./manage.sh restore archivo.tar.gz    # Restaurar desde backup
./manage.sh restore --from-s3 archivo # Restaurar desde S3
```

## **🔐 Seguridad y SSL**

### **SSL/HTTPS Automático (Si tienes dominio)**

```bash
# Configurar SSL con Let's Encrypt
./manage.sh setup-ssl tudominio.com admin@tudominio.com

# Después de esto:
# ✅ Tu Odoo estará en: https://tudominio.com
# ✅ Certificado renovación automática
# ✅ Redirección HTTP → HTTPS automática
```

### **Configuración de Seguridad**

Tu configuración actual permite acceso desde cualquier IP:
```hcl
allowed_ssh_cidr = "0.0.0.0/0"  # Acceso desde cualquier IP
```

**Para mayor seguridad:**
```bash
# Obtener tu IP pública
curl ifconfig.me

# Editar terraform.tfvars
allowed_ssh_cidr = "TU_IP/32"  # Solo tu IP

# Aplicar cambio
cd terraform && terraform apply
```

## **💰 Optimización de Costos**

### **Tu Configuración Actual (Muy Económica)**

```
💰 Costos Estimados Mensuales:
┌─────────────────────────────────────────────┐
│ EC2 t3.medium Spot: ~$15-25/mes            │
│ Disco EBS 30GB: ~$3/mes                    │
│ Elastic IP: ~$3.6/mes                      │
│ Transferencia datos: ~$1-5/mes             │
│ ────────────────────────────────────────────│
│ TOTAL: ~$22-37/mes                         │
│ (vs $80-120/mes instancia normal)          │
└─────────────────────────────────────────────┘
```

### **Monitoreo de Costos**

```bash
# Ver costos actuales
./manage.sh costs

# Configurar alertas de costos (opcional)
./manage.sh setup-cost-alerts 50  # Alerta si supera $50/mes
```

### **Optimización para Desarrollo**

```bash
# En terraform.tfvars para ahorrar más:
instance_type = "t3.small"      # Instancia más pequeña
spot_price = "0.02"             # Precio spot más bajo
root_volume_size = 20           # Disco más pequeño
```

## **🚨 Solución de Problemas**

### **Error: "No se pudo obtener la IP de la instancia"**

```bash
# Verificar estado de Terraform
cd terraform
terraform output

# Si no hay outputs:
terraform refresh
terraform output

# Si persiste, re-desplegar:
cd .. && ./deploy.sh --deploy
```

### **Error: "Odoo no responde"**

```bash
# 1. Verificar si aún se está configurando (esperar 5-10 min)
./manage.sh status

# 2. Ver logs para diagnóstico
./manage.sh logs odoo

# 3. Reiniciar servicios si es necesario
./manage.sh restart

# 4. Verificar que Docker está funcionando
./manage.sh remote "sudo docker ps"
```

### **Error: "Permission denied" en SSH**

```bash
# Verificar que existe tu clave
ls -la ~/.ssh/*.pem

# Verificar permisos de la clave
chmod 400 ~/.ssh/tu-clave.pem

# Verificar nombre de la clave en configuración
grep key_pair_name terraform/terraform.tfvars
```

### **Error: "AWS credentials not configured"**

```bash
# Configurar AWS CLI
aws configure

# Verificar configuración
aws sts get-caller-identity

# Verificar permisos IAM necesarios
aws ec2 describe-regions
```

### **Error: "Spot instance terminated"**

```bash
# Las spot instances pueden terminarse si hay alta demanda
# Verificar estado:
./manage.sh status

# Re-desplegar si es necesario:
./deploy.sh

# Para mayor estabilidad, usar instancia normal:
# En terraform.tfvars cambiar por instancia normal:
# spot_price = ""  # Dejar vacío para instancia normal
```

## **📋 Checklist de Despliegue Exitoso**

### **Pre-Despliegue**
- [ ] ✅ Terraform instalado (`terraform --version`)
- [ ] ✅ AWS CLI instalado (`aws --version`)
- [ ] ✅ AWS configurado (`aws sts get-caller-identity`)
- [ ] ✅ Key Pair identificado (`aws ec2 describe-key-pairs`)
- [ ] ✅ `terraform.tfvars` configurado con `key_pair_name` real

### **Durante Despliegue**
- [ ] ✅ `./deploy.sh` ejecutado sin errores
- [ ] ✅ Terraform apply completado exitosamente
- [ ] ✅ Instancia EC2 creada y funcionando
- [ ] ✅ IP pública asignada correctamente

### **Post-Despliegue**
- [ ] ✅ `./manage.sh status` muestra todos los servicios activos
- [ ] ✅ Acceso web funciona (`http://IP-DEL-SERVIDOR`)
- [ ] ✅ SSH funciona (`./manage.sh ssh`)
- [ ] ✅ Base de datos creada en Odoo
- [ ] ✅ Backup inicial creado (`./manage.sh backup`)
- [ ] ✅ SSL configurado (si tienes dominio)

## **🔄 Mantenimiento y Actualizaciones**

### **Actualizaciones Controladas**

```bash
# 1. Backup obligatorio antes de actualizar
./manage.sh backup

# 2. Actualizar contenedores uno por uno
./manage.sh remote "cd /efs/HLP-ERP-ODOO-17 && docker-compose pull odoo"
./manage.sh remote "cd /efs/HLP-ERP-ODOO-17 && docker-compose up -d odoo"

# 3. Verificar funcionamiento
./manage.sh status
./manage.sh logs odoo

# 4. Repetir para otros servicios si es necesario
```

### **Mantenimiento Regular**

```bash
# Semanal
./manage.sh backup                # Backup semanal
./manage.sh monitor               # Revisar recursos
./manage.sh costs                 # Revisar costos

# Mensual
./manage.sh update                # Actualizar contenedores
./manage.sh cleanup               # Limpiar logs y archivos temporales
```

## **🎯 Comandos de Conexión SSH**

### **Conexión Básica**

```bash
# Usando el script (recomendado)
./manage.sh ssh

# Conexión manual
ssh -i ~/.ssh/tu-clave.pem ec2-user@IP-DEL-SERVIDOR
```

### **Comandos Útiles en el Servidor**

```bash
# Una vez conectado por SSH:

# Ver contenedores Docker
sudo docker ps

# Logs de servicios
sudo docker-compose -f /efs/HLP-ERP-ODOO-17/docker-compose.yml logs -f

# Ver uso de recursos
htop
df -h
free -h

# Reiniciar servicios
sudo docker-compose -f /efs/HLP-ERP-ODOO-17/docker-compose.yml restart

# Ver configuración de Odoo
sudo cat /efs/HLP-ERP-ODOO-17/ODOO/config/odoo.conf
```

## **📱 Acceso Móvil**

Odoo incluye interfaz móvil optimizada:
- 📱 **URL móvil**: `http://IP-DEL-SERVIDOR` (misma URL)
- 📱 **App Odoo**: Disponible en App Store y Google Play
- 📱 **Configuración**: Usar la IP o dominio de tu servidor

## **🎉 ¡Felicidades!**

Tu servidor Helipistas ERP con Odoo 17 está funcionando con:

- ✅ **AWS EC2 Spot Instance** (60-90% más barato)
- ✅ **Docker optimizado** para producción
- ✅ **Nginx con caché** para mejor rendimiento
- ✅ **PostgreSQL 15** optimizado
- ✅ **Backups automáticos** incluidos
- ✅ **SSL/HTTPS** opcional
- ✅ **Monitoreo** y alertas
- ✅ **Scripts de gestión** completos

---

## **📞 Soporte y Recursos**

### **Documentación Adicional**
- 📖 `QUICKSTART.md`: Guía de inicio en 5 minutos
- 🏗️ `PROYECTO-ESTRUCTURA.md`: Estructura detallada del proyecto
- ⚡ `TERRAFORM_VS_AWS_CLI.md`: Comparativa de herramientas

### **Comandos de Ayuda**
```bash
./deploy.sh --help          # Ayuda del despliegue
./manage.sh --help          # Ayuda de gestión
./manage.sh info            # Información de conexión
```

**🚀 Tu servidor ERP está listo para producción. ¡A trabajar!**
