# 🚀 Helipistas ERP - Odoo 17 en AWS

## 📋 Índice

1. [Descripción General](#-descripción-general)
2. [Arquitectura del Sistema](#-arquitectura-del-sistema)
3. [Estructura del Proyecto](#-estructura-del-proyecto)
4. [Requisitos Previos](#-requisitos-previos)
5. [Configuración Inicial](#-configuración-inicial)
6. [Despliegue de Infraestructura](#-despliegue-de-infraestructura)
7. [Flujo de Deployment Automático](#-flujo-de-deployment-automático)
8. [Gestión y Mantenimiento](#-gestión-y-mantenimiento)
9. [Arquitectura de Datos](#-arquitectura-de-datos)
10. [Seguridad y SSL](#-seguridad-y-ssl)
11. [Troubleshooting](#-troubleshooting)
12. [Referencias Técnicas](#-referencias-técnicas)

---

## 📖 Descripción General

Este proyecto implementa una infraestructura completa de **Odoo 17 ERP** en AWS usando **Infrastructure as Code (Terraform)**, con despliegue completamente automatizado, alta disponibilidad mediante EFS, SSL/HTTPS automático con Let's Encrypt, y arquitectura basada en contenedores Docker.

### 🎯 Características Principales

- ✅ **Despliegue Completamente Automatizado**: Un solo comando (`terraform apply`) despliega toda la infraestructura
- ✅ **Persistencia de Datos con EFS**: Los datos sobreviven a la recreación de instancias EC2
- ✅ **SSL/HTTPS Automático**: Certificados Let's Encrypt con renovación automática
- ✅ **Arquitectura Docker**: PostgreSQL 15 + Odoo 17 + Nginx con proxy reverso
- ✅ **Alta Disponibilidad**: EFS compartido permite múltiples instancias
- ✅ **IP Estática**: Elastic IP reutilizable para mantener DNS consistente
- ✅ **Infraestructura Reproducible**: Terraform permite recrear la infraestructura idéntica en cualquier momento
- ✅ **Configuración Optimizada**: Odoo configurado para producción con workers y proxy mode

### 💡 Casos de Uso

- **Empresas que necesitan ERP robusto y económico** en la nube
- **Desarrollo y testing** con infraestructura efímera
- **Múltiples ambientes** (dev, staging, producción) con la misma configuración
- **Disaster recovery** con capacidad de recrear infraestructura rápidamente

---

## 🏗️ Arquitectura del Sistema

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ HTTPS (443) / HTTP (80)
                     │
┌────────────────────▼────────────────────────────────────────┐
│              AWS Elastic IP (54.228.16.152)                  │
│              DNS: erp17.helipistas.com                       │
└────────────────────┬────────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────────┐
│                   EC2 Instance (t3.medium)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         Docker Container: Nginx (Proxy Reverso)      │   │
│  │  - SSL Termination (Let's Encrypt)                  │   │
│  │  - Proxy Pass a Odoo                                │   │
│  │  - Certificados auto-renovables                     │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │         Docker Container: Odoo 17                    │   │
│  │  - Puerto 8069                                       │   │
│  │  - 2 Workers configurados                           │   │
│  │  - Proxy mode habilitado                            │   │
│  └──────────────────┬───────────────────────────────────┘   │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐   │
│  │         Docker Container: PostgreSQL 15              │   │
│  │  - Puerto 5432                                       │   │
│  │  - Usuario: odoo                                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    Volumes montados desde EFS (fs-ec7152d9)          │   │
│  │  /efs/HELIPISTAS-ODOO-17/                            │   │
│  │    ├── postgres/      (Base de datos)                │   │
│  │    ├── odoo/          (Addons, filestore, config)    │   │
│  │    ├── nginx/         (Configuración)                │   │
│  │    └── certbot/       (Certificados SSL)             │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
                     │
                     │ NFS4 Mount
                     │
┌────────────────────▼────────────────────────────────────────┐
│         AWS EFS (Elastic File System)                        │
│         fs-ec7152d9.efs.eu-west-1.amazonaws.com             │
│  - Almacenamiento persistente                               │
│  - Compartido entre instancias                              │
│  - Backups automáticos de AWS                               │
└──────────────────────────────────────────────────────────────┘
```

### Componentes Clave

| Componente | Tecnología | Propósito |
|------------|-----------|-----------|
| **EC2 Instance** | Amazon Linux 2 (t3.medium) | Servidor de aplicaciones |
| **EFS** | AWS Elastic File System | Almacenamiento persistente compartido |
| **Elastic IP** | AWS EIP (eipalloc-0184418cc26d4e66f) | IP pública estática |
| **VPC** | vpc-92d074f6 | Red virtual privada existente |
| **Security Group** | HELIPISTAS-ODOO-17-SG | Firewall de red |
| **Odoo** | Docker odoo:17 | Aplicación ERP |
| **PostgreSQL** | Docker postgres:15 | Base de datos |
| **Nginx** | Docker nginx:latest | Proxy reverso y SSL |
| **Certbot** | Docker certbot/certbot | Gestión de certificados SSL |

---

## 📂 Estructura del Proyecto

```
SERVER-SCRIPTS/
│
├── terraform/                          # 🏗️ Infraestructura como código
│   ├── main.tf                        # Definición de recursos AWS
│   ├── variables.tf                   # Variables configurables
│   ├── outputs.tf                     # Outputs del deployment
│   ├── terraform.tfvars               # Configuración específica (GITIGNORED)
│   ├── terraform.tfvars.example       # Ejemplo de configuración
│   ├── user_data_simple.sh            # Script de inicialización EC2
│   └── templates/                     # Plantillas de configuración
│       ├── docker-compose.yml
│       ├── nginx.conf
│       └── odoo.conf
│
├── setup_odoo_complete.sh             # 🔧 Script principal de configuración
│                                       # (Se descarga y ejecuta desde GitHub)
│
├── docker/                            # 🐳 Configuración Docker (referencia)
│   ├── docker-compose.yml
│   ├── config/odoo.conf
│   └── nginx/
│       ├── nginx.conf
│       └── default.conf
│
├── scripts/                           # 🛠️ Utilidades de mantenimiento
│   ├── backup.sh                     # Backup de datos
│   ├── restore.sh                    # Restauración de backups
│   └── monitor.sh                    # Monitoreo de servicios
│
├── README.md                          # 📖 Este archivo
├── LICENSE                            # 📄 Licencia MIT
└── .gitignore                        # 🙈 Archivos ignorados
```

### Archivos Clave

#### `terraform/main.tf`
Define toda la infraestructura AWS:
- Data sources para VPC, subnet y AMI existentes
- Security Group con puertos 22, 80, 443, 8069
- Instancia EC2 con user_data que ejecuta `user_data_simple.sh`
- Asociación de Elastic IP a la instancia

#### `terraform/user_data_simple.sh`
Script que se ejecuta al crear la instancia EC2:
1. Instala dependencias (Docker, AWS CLI, NFS utils)
2. Monta el EFS en `/efs`
3. Crea estructura de directorios
4. Descarga `setup_odoo_complete.sh` desde GitHub
5. Ejecuta el setup completo

#### `setup_odoo_complete.sh`
Script principal alojado en GitHub que:
1. Corrige permisos para contenedores Docker
2. Crea `docker-compose.yml` dinámicamente
3. Crea configuración de Nginx (HTTP inicial)
4. Crea configuración de Odoo (`odoo.conf`)
5. Inicia servicios (PostgreSQL, Odoo, Nginx)
6. Obtiene certificado SSL de Let's Encrypt
7. Reconfigura Nginx para HTTPS
8. Inicia servicio certbot para renovación automática

---

## 🔧 Requisitos Previos

### 1. Herramientas Necesarias

| Herramienta | Versión Mínima | Instalación |
|-------------|----------------|-------------|
| **AWS CLI** | 2.x | `brew install awscli` (macOS) |
| **Terraform** | 1.0+ | `brew install terraform` (macOS) |
| **SSH Client** | Cualquiera | Incluido en sistemas Unix |
| **Git** | 2.x | `brew install git` (macOS) |

### 2. Cuentas y Credenciales

- **Cuenta de AWS** con permisos para:
  - EC2 (create, describe, terminate instances)
  - EFS (describe file systems)
  - VPC (describe VPCs, subnets, security groups)
  - Elastic IP (associate, describe addresses)

- **AWS CLI configurado** con credenciales válidas:
  ```bash
  aws configure
  # AWS Access Key ID: [tu_access_key]
  # AWS Secret Access Key: [tu_secret_key]
  # Default region: eu-west-1
  # Default output format: json
  ```

### 3. Recursos AWS Existentes

Este proyecto **reutiliza recursos existentes**:

| Recurso | ID | Región | Notas |
|---------|-----|--------|-------|
| **VPC** | vpc-92d074f6 | eu-west-1 | VPC WEBS existente |
| **Subnet** | subnet-c362e2a7 | eu-west-1b | Subnet pública |
| **EFS** | fs-ec7152d9 | eu-west-1 | Almacenamiento persistente |
| **Elastic IP** | eipalloc-0184418cc26d4e66f | eu-west-1 | IP: 54.228.16.152 |
| **Key Pair** | ERP | eu-west-1 | Par de claves SSH |

**IMPORTANTE**: Estos recursos NO se crean ni destruyen por Terraform. Solo se **referencian y utilizan**.

### 4. Archivo PEM de SSH

- Archivo: `/Users/emiloalvarez/Work/PEMFiles/ERP.pem`
- Permisos: `chmod 400 ERP.pem`
- Uso: Conexión SSH a la instancia EC2

---

## ⚙️ Configuración Inicial

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/leulit/helipistas-erp-odoo-17-server-scripts.git
cd helipistas-erp-odoo-17-server-scripts/terraform
```

### Paso 2: Crear Archivo de Configuración

Copia el archivo de ejemplo y edítalo:

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### Paso 3: Configurar `terraform.tfvars`

```hcl
# Configuración AWS
aws_region = "eu-west-1"
resource_prefix = "HELIPISTAS-ODOO-17"

# Tipo de instancia
instance_type = "t3.medium"  # 2 vCPU, 4GB RAM

# Tamaño del disco raíz
root_volume_size = 30  # GB

# Key Pair SSH (sin extensión .pem)
key_pair_name = "ERP"

# Contraseñas (CAMBIAR POR VALORES SEGUROS)
postgres_password = "TU_PASSWORD_POSTGRESQL_SEGURO"
odoo_master_password = "TU_PASSWORD_ODOO_MASTER_SEGURO"

# Recursos existentes (NO CAMBIAR)
existing_elastic_ip_id = "eipalloc-0184418cc26d4e66f"
existing_efs_id = "fs-ec7152d9"

# Dominio para SSL
domain_name = "erp17.helipistas.com"
```

⚠️ **CRÍTICO**: El archivo `terraform.tfvars` contiene contraseñas sensibles y está en `.gitignore`. **NUNCA** lo subas a Git.

### Paso 4: Generar Contraseñas Seguras

```bash
# Generar contraseña aleatoria de 32 caracteres
openssl rand -base64 32

# O usar un generador online (pero mejor local por seguridad)
```

### Paso 5: Configurar DNS

El dominio `erp17.helipistas.com` debe apuntar a la Elastic IP:

```
Tipo: A
Nombre: erp17.helipistas.com
Valor: 54.228.16.152
TTL: 300
```

---

## 🚀 Despliegue de Infraestructura

### Opción 1: Despliegue Completo (Recomendado)

Este comando **destruye** la infraestructura existente (si existe) y crea una nueva desde cero:

```bash
cd terraform
terraform init
terraform destroy -auto-approve && terraform apply -auto-approve
```

**Duración**: 10-12 minutos
- Terraform apply: 2-3 minutos
- Setup automático: 8-9 minutos

### Opción 2: Solo Crear (Si no existe infraestructura)

```bash
cd terraform
terraform init
terraform apply
```

### Opción 3: Solo Destruir

```bash
cd terraform
terraform destroy
```

⚠️ **NOTA**: Destruir la infraestructura NO elimina:
- EFS (los datos persisten)
- Elastic IP
- VPC y subnet
- Key Pair

---

## 🔄 Flujo de Deployment Automático

Cuando ejecutas `terraform apply`, este es el flujo completo:

### 1️⃣ **Terraform Crea la Instancia EC2** (2-3 min)

```
Terraform aplica main.tf:
├── Consulta VPC, subnet, AMI existentes
├── Crea Security Group
├── Lanza instancia EC2 (Amazon Linux 2, t3.medium)
├── Asocia Elastic IP
└── Inyecta user_data_simple.sh
```

### 2️⃣ **user_data_simple.sh se Ejecuta** (3-4 min)

```
Script de inicialización EC2:
├── Actualiza sistema (yum update)
├── Instala Docker, AWS CLI, NFS utils
├── Inicia Docker
├── Instala Docker Compose
├── Monta EFS en /efs
│   └── mount -t nfs4 fs-ec7152d9.efs.eu-west-1.amazonaws.com:/ /efs
├── Crea estructura de directorios
│   └── /efs/HELIPISTAS-ODOO-17/{postgres,odoo,nginx,certbot}
└── Descarga y ejecuta setup_odoo_complete.sh desde GitHub
```

### 3️⃣ **setup_odoo_complete.sh Configura Todo** (5-6 min)

```
Script principal de configuración:
├── 1. Corrige permisos de directorios (chown 101:101, 999:999)
├── 2. Crea docker-compose.yml dinámicamente
│   ├── PostgreSQL 15 (puerto 5432)
│   ├── Odoo 17 (puerto 8069)
│   ├── Nginx (puertos 80, 443)
│   └── Certbot (renovación SSL)
├── 3. Crea configuración de Nginx (HTTP inicial)
│   └── nginx/conf/default.conf (proxy a Odoo, soporte ACME challenge)
├── 4. Crea configuración de Odoo
│   └── odoo/conf/odoo.conf (workers, proxy_mode, paths)
├── 5. Inicia servicios básicos
│   ├── docker-compose up -d postgresOdoo16
│   ├── docker-compose up -d helipistas_odoo
│   └── docker-compose up -d nginx
│   └── Espera 45 segundos para que servicios estén listos
├── 6. Obtiene certificado Let's Encrypt
│   └── docker run certbot/certbot certonly --webroot \
│       --force-renewal --non-interactive -d erp17.helipistas.com
├── 7. Reconfigura Nginx para HTTPS
│   ├── Actualiza nginx/conf/default.conf
│   ├── HTTP → redirige a HTTPS
│   └── HTTPS → proxy a Odoo con SSL
├── 8. Reinicia Nginx con configuración SSL
│   └── docker-compose restart nginx
└── 9. Inicia servicio certbot para auto-renovación
    └── docker-compose up -d certbot
```

### 4️⃣ **Verificación Automática**

```
Checks de salud:
├── PostgreSQL escuchando en 5432 ✓
├── Odoo respondiendo en 8069 ✓
├── Nginx proxy en 80/443 ✓
├── Certificado SSL válido ✓
└── DNS resolviendo correctamente ✓
```

### 5️⃣ **Sistema Listo** 🎉

```
URLs disponibles:
├── HTTP:  http://erp17.helipistas.com (→ redirige a HTTPS)
├── HTTPS: https://erp17.helipistas.com (acceso principal)
└── Direct: http://54.228.16.152:8069 (Odoo directo, solo desarrollo)
```

---

## 🛠️ Gestión y Mantenimiento

### Conectarse a la Instancia

```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
```

### Comandos de Docker Compose

Todos los comandos se ejecutan desde `/efs/HELIPISTAS-ODOO-17`:

```bash
cd /efs/HELIPISTAS-ODOO-17

# Ver estado de contenedores
docker-compose ps

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f helipistas_odoo
docker-compose logs -f postgresOdoo16
docker-compose logs -f nginx

# Reiniciar un servicio
docker-compose restart helipistas_odoo

# Reiniciar todos los servicios
docker-compose restart

# Parar todos los servicios
docker-compose down

# Iniciar todos los servicios
docker-compose up -d

# Ver recursos consumidos
docker stats
```

### Verificar Certificado SSL

```bash
# Ver detalles del certificado
sudo docker run --rm \
  -v /efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt \
  certbot/certbot certificates

# Renovar certificado manualmente
sudo docker run --rm \
  -v /efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot \
  -v /efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt \
  certbot/certbot renew --force-renewal --non-interactive

# Después de renovar, reiniciar Nginx
cd /efs/HELIPISTAS-ODOO-17
docker-compose restart nginx
```

### Monitorear Logs del Sistema

```bash
# Logs de cloud-init (setup inicial)
sudo tail -f /var/log/cloud-init-output.log

# Logs del setup completo
sudo tail -f /var/log/odoo-setup-complete.log

# Logs del sistema
sudo journalctl -f
```

### Verificar Montaje de EFS

```bash
# Ver punto de montaje
df -h | grep efs

# Ver detalles del montaje
mount | grep efs

# Verificar contenido
ls -la /efs/HELIPISTAS-ODOO-17/
```

---

## 💾 Arquitectura de Datos

### Estructura en EFS

```
/efs/HELIPISTAS-ODOO-17/
│
├── postgres/                          # 🗄️ Base de datos PostgreSQL
│   └── pgdata/                       # Datos de la base de datos
│       ├── base/                     # Tablas y datos
│       ├── global/                   # Configuración global
│       ├── pg_wal/                   # Write-Ahead Logs
│       └── postgresql.conf           # Configuración PostgreSQL
│
├── odoo/                             # 🎯 Aplicación Odoo
│   ├── conf/                         # Configuración
│   │   └── odoo.conf                # Archivo de configuración principal
│   ├── addons/                       # Módulos personalizados
│   ├── filestore/                    # Archivos subidos por usuarios
│   │   └── [database_name]/         # Un directorio por base de datos
│   └── sessiones/                    # Sesiones de usuario
│
├── nginx/                            # 🌐 Proxy reverso
│   ├── conf/                         # Configuración
│   │   └── default.conf             # Virtual host
│   └── ssl/                          # Certificados SSL personalizados
│
└── certbot/                          # 🔒 Let's Encrypt
    ├── conf/                         # Configuración y certificados
    │   ├── live/                     # Certificados activos
    │   │   └── erp17.helipistas.com/
    │   │       ├── fullchain.pem    # Certificado + cadena
    │   │       ├── privkey.pem      # Clave privada
    │   │       └── cert.pem         # Certificado
    │   ├── archive/                  # Archivo de certificados antiguos
    │   └── renewal/                  # Configuración de renovación
    └── www/                          # Webroot para validación ACME
        └── .well-known/
            └── acme-challenge/
```

### Persistencia de Datos

| Tipo de Dato | Ubicación | Persistencia | Backup |
|--------------|-----------|--------------|--------|
| **Base de datos PostgreSQL** | `/efs/.../postgres/pgdata` | ✅ Persiste en EFS | Automático por AWS EFS |
| **Archivos de Odoo** | `/efs/.../odoo/filestore` | ✅ Persiste en EFS | Automático por AWS EFS |
| **Configuración Odoo** | `/efs/.../odoo/conf` | ✅ Persiste en EFS | Automático por AWS EFS |
| **Módulos custom** | `/efs/.../odoo/addons` | ✅ Persiste en EFS | Automático por AWS EFS |
| **Certificados SSL** | `/efs/.../certbot/conf` | ✅ Persiste en EFS | Automático por AWS EFS |
| **Logs de contenedores** | Dentro de contenedores | ❌ Efímero | Ver con `docker logs` |

### Ventajas de la Arquitectura

1. **Datos Sobreviven a Recreación de Instancias**: Si destruyes y recreas la EC2, todos los datos permanecen en EFS
2. **Escalabilidad Horizontal**: Múltiples instancias EC2 pueden montar el mismo EFS
3. **Backups Automáticos**: AWS EFS tiene backups automáticos
4. **Alta Disponibilidad**: EFS está replicado en múltiples zonas de disponibilidad

---

## 🔐 Seguridad y SSL

### Security Group

El Security Group `HELIPISTAS-ODOO-17-SG` permite:

| Puerto | Protocolo | Origen | Propósito |
|--------|-----------|--------|-----------|
| 22 | TCP | 0.0.0.0/0 | SSH (administración) |
| 80 | TCP | 0.0.0.0/0 | HTTP (redirige a HTTPS) |
| 443 | TCP | 0.0.0.0/0 | HTTPS (acceso principal) |
| 8069 | TCP | 0.0.0.0/0 | Odoo directo (opcional) |
| 2049 | TCP | Security Group mismo | NFS para EFS |

### Certificados SSL

#### Obtención Automática

Let's Encrypt emite certificados válidos automáticamente durante el deployment:

```bash
# El script ejecuta:
docker run --rm certbot/certbot \
  certonly --webroot --webroot-path=/var/www/certbot \
  --email admin@helipistas.com \
  --agree-tos --no-eff-email \
  --force-renewal --non-interactive \
  -d erp17.helipistas.com
```

#### Renovación Automática

El contenedor `certbot` se ejecuta continuamente y renueva certificados cada 12 horas:

```yaml
certbot:
  image: certbot/certbot
  entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
```

#### Verificar Certificado

```bash
# Ver información del certificado
openssl s_client -connect erp17.helipistas.com:443 -servername erp17.helipistas.com < /dev/null 2>/dev/null | openssl x509 -noout -dates

# Ver Subject Alternative Names
openssl s_client -connect erp17.helipistas.com:443 -servername erp17.helipistas.com < /dev/null 2>/dev/null | openssl x509 -noout -text | grep -A1 "Subject Alternative Name"
```

### Contraseñas

| Servicio | Variable | Uso |
|----------|----------|-----|
| PostgreSQL | `postgres_password` | Conexión de Odoo a la base de datos |
| Odoo Master | `odoo_master_password` | Gestión de bases de datos en Odoo |

**IMPORTANTE**: 
- Estas contraseñas se pasan como parámetros desde Terraform
- Se almacenan en `terraform.tfvars` (excluido de Git)
- Se usan en docker-compose.yml y odoo.conf

---

## 🐛 Troubleshooting

### Problema: Terraform falla al crear la instancia

**Síntomas**:
```
Error: Error launching source instance: InvalidKeyPair.NotFound
```

**Solución**:
Verificar que el Key Pair "ERP" existe en AWS:
```bash
aws ec2 describe-key-pairs --region eu-west-1 --key-names ERP
```

---

### Problema: EFS no se monta

**Síntomas**:
```
mount: mounting fs-ec7152d9.efs.eu-west-1.amazonaws.com:/ on /efs failed
```

**Solución**:
1. Verificar que EFS existe y está disponible:
```bash
aws efs describe-file-systems --file-system-id fs-ec7152d9 --region eu-west-1
```

2. Verificar Security Group permite NFS (puerto 2049)
3. Conectarse a la instancia y verificar logs:
```bash
sudo tail -f /var/log/cloud-init-output.log
```

---

### Problema: Certificado SSL no se obtiene

**Síntomas**:
```
Error: No se pudo obtener el certificado SSL
```

**Soluciones**:

1. **Verificar DNS**:
```bash
nslookup erp17.helipistas.com
# Debe resolver a 54.228.16.152
```

2. **Verificar que Nginx está corriendo**:
```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
docker-compose ps
```

3. **Verificar logs de certbot**:
```bash
docker logs helipistas_certbot
```

4. **Intentar obtener certificado manualmente**:
```bash
cd /efs/HELIPISTAS-ODOO-17
docker run --rm --name certbot-manual \
  -v "/efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot" \
  -v "/efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt" \
  certbot/certbot \
  certonly --webroot --webroot-path=/var/www/certbot \
  --email admin@helipistas.com --agree-tos --no-eff-email \
  --force-renewal --non-interactive \
  -d erp17.helipistas.com
```

---

### Problema: Odoo no arranca

**Síntomas**:
Container `helipistas_odoo` en estado `Restarting` o `Exited`

**Solución**:

1. **Ver logs de Odoo**:
```bash
docker logs helipistas_odoo
```

2. **Verificar PostgreSQL**:
```bash
docker logs helipistas_postgres
docker exec helipistas_postgres psql -U odoo -c "\l"
```

3. **Verificar configuración**:
```bash
cat /efs/HELIPISTAS-ODOO-17/odoo/conf/odoo.conf
```

4. **Verificar permisos**:
```bash
ls -la /efs/HELIPISTAS-ODOO-17/odoo/
# Debe ser 101:101 (usuario odoo en el contenedor)
```

---

### Problema: No puedo acceder a Odoo desde el navegador

**Síntomas**:
`https://erp17.helipistas.com` no carga

**Diagnóstico paso a paso**:

1. **Verificar DNS**:
```bash
nslookup erp17.helipistas.com
# Debe resolver a 54.228.16.152
```

2. **Verificar que Elastic IP está asociada**:
```bash
aws ec2 describe-addresses --region eu-west-1 --allocation-ids eipalloc-0184418cc26d4e66f
```

3. **Verificar que Nginx está escuchando**:
```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
sudo netstat -tlnp | grep -E ':(80|443)'
```

4. **Verificar Security Group permite tráfico**:
```bash
aws ec2 describe-security-groups --region eu-west-1 --filters "Name=group-name,Values=HELIPISTAS-ODOO-17-SG"
```

5. **Ver logs de Nginx**:
```bash
docker logs helipistas_nginx
```

6. **Probar acceso directo a Odoo**:
```bash
curl http://54.228.16.152:8069
```

---

### Problema: Deployment se queda colgado en certbot

**Síntomas**:
El script se detiene esperando input de certbot

**Causa**:
Certificado ya existe y certbot pide confirmación interactiva

**Solución**:
El script ya incluye los flags `--force-renewal` y `--non-interactive`, pero si falla:

```bash
# Conectarse a la instancia
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Matar proceso de certbot
sudo pkill -f certbot

# Ejecutar certbot con flags correctos
cd /efs/HELIPISTAS-ODOO-17
docker run --rm --name certbot-fix \
  -v "/efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot" \
  -v "/efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt" \
  certbot/certbot \
  certonly --webroot --webroot-path=/var/www/certbot \
  --email admin@helipistas.com --agree-tos --no-eff-email \
  --force-renewal --non-interactive \
  -d erp17.helipistas.com

# Reiniciar Nginx
docker-compose restart nginx
```

---

## 📚 Referencias Técnicas

### Comandos Útiles

#### Terraform

```bash
# Inicializar Terraform (primera vez o después de cambios en providers)
terraform init

# Ver plan de cambios sin aplicar
terraform plan

# Aplicar cambios
terraform apply

# Aplicar sin confirmación
terraform apply -auto-approve

# Destruir infraestructura
terraform destroy

# Destruir sin confirmación
terraform destroy -auto-approve

# Ver outputs
terraform output

# Ver estado
terraform show

# Formatear archivos .tf
terraform fmt

# Validar configuración
terraform validate
```

#### Docker Compose (en la instancia)

```bash
# Ubicación de trabajo
cd /efs/HELIPISTAS-ODOO-17

# Ver estado de servicios
docker-compose ps

# Ver logs (todos los servicios)
docker-compose logs -f

# Ver logs (servicio específico)
docker-compose logs -f [helipistas_odoo|postgresOdoo16|nginx|certbot]

# Reiniciar un servicio
docker-compose restart [nombre_servicio]

# Reiniciar todos los servicios
docker-compose restart

# Parar todos los servicios
docker-compose down

# Iniciar todos los servicios
docker-compose up -d

# Iniciar servicio específico
docker-compose up -d [nombre_servicio]

# Ver recursos (CPU, RAM)
docker stats

# Ejecutar comando en contenedor
docker exec -it helipistas_odoo bash
docker exec -it helipistas_postgres psql -U odoo

# Ver redes
docker network ls
docker network inspect helipistas-odoo-17_helipistas_network
```

#### AWS CLI

```bash
# Listar instancias EC2
aws ec2 describe-instances --region eu-west-1 --filters "Name=tag:Name,Values=HELIPISTAS-ODOO-17-INSTANCE"

# Ver Elastic IPs
aws ec2 describe-addresses --region eu-west-1

# Ver EFS
aws efs describe-file-systems --region eu-west-1

# Ver Security Groups
aws ec2 describe-security-groups --region eu-west-1 --filters "Name=group-name,Values=HELIPISTAS-ODOO-17-SG"
```

### Variables de Entorno en Docker Compose

| Variable | Servicio | Valor | Descripción |
|----------|----------|-------|-------------|
| `POSTGRES_USER` | postgresOdoo16 | odoo | Usuario de PostgreSQL |
| `POSTGRES_PASSWORD` | postgresOdoo16 | [desde terraform] | Contraseña de PostgreSQL |
| `POSTGRES_DB` | postgresOdoo16 | postgres | Base de datos por defecto |
| `PGDATA` | postgresOdoo16 | /var/lib/postgresql/data/pgdata | Directorio de datos |
| `HOST` | helipistas_odoo | postgresOdoo16 | Host de PostgreSQL |
| `USER` | helipistas_odoo | odoo | Usuario para conectar a PostgreSQL |
| `PASSWORD` | helipistas_odoo | [desde terraform] | Contraseña para PostgreSQL |

### Puertos Expuestos

| Servicio | Puerto Interno | Puerto Host | Acceso |
|----------|----------------|-------------|--------|
| PostgreSQL | 5432 | 5432 | Solo red Docker |
| Odoo | 8069 | 8069 | Público (opcional) |
| Nginx HTTP | 80 | 80 | Público |
| Nginx HTTPS | 443 | 443 | Público |

### Configuración de Odoo

El archivo `/efs/HELIPISTAS-ODOO-17/odoo/conf/odoo.conf` contiene:

```ini
[options]
# Database configuration
db_host = postgresOdoo16
db_port = 5432
db_user = odoo
db_password = [POSTGRES_PASSWORD]
admin_passwd = [ODOO_MASTER_PASSWORD]

# Workers configuration
workers = 2
max_cron_threads = 1

# File paths
addons_path = /mnt/extra-addons,/usr/lib/python3/dist-packages/odoo/addons
data_dir = /var/lib/odoo

# Logging
log_level = info
log_handler = :INFO

# Security
list_db = True
dbfilter = ^.*$

# Performance
limit_memory_hard = 1677721600
limit_memory_soft = 1342177280
limit_request = 8192
limit_time_cpu = 600
limit_time_real = 1200

# Proxy mode (for Nginx)
proxy_mode = True

# Session
session_dir = /var/lib/odoo/sessions
```

### Configuración de Nginx (HTTPS)

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name erp17.helipistas.com;
    
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
    server_name erp17.helipistas.com;

    # SSL certificates from Let's Encrypt
    ssl_certificate /etc/letsencrypt/live/erp17.helipistas.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/erp17.helipistas.com/privkey.pem;

    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Proxy to Odoo
    location / {
        proxy_pass http://helipistas_odoo:8069;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## 🔄 Workflow de Evolución del Proyecto

### Para Desarrolladores Nuevos

1. **Clonar repositorio**:
   ```bash
   git clone https://github.com/leulit/helipistas-erp-odoo-17-server-scripts.git
   ```

2. **Revisar documentación**:
   - Leer este README completo
   - Revisar archivos en `terraform/`
   - Entender `setup_odoo_complete.sh`

3. **Configurar entorno local**:
   - Instalar AWS CLI y Terraform
   - Configurar credenciales AWS
   - Obtener archivo PEM

4. **Crear ambiente de pruebas**:
   - Copiar `terraform.tfvars.example` a `terraform.tfvars`
   - Cambiar `resource_prefix` a algo único (ej: `PRUEBAS-NOMBRE`)
   - NO usar los IDs de producción
   - Ejecutar `terraform apply`

5. **Probar cambios**:
   - Hacer modificaciones en scripts
   - Subir a branch en GitHub
   - Modificar `user_data_simple.sh` para descargar desde tu branch
   - Desplegar y probar

6. **Mergear a main**:
   - Una vez probado, hacer PR a `main`
   - Los deployments de producción usan la branch `main`

### Modificar el Deployment

#### Cambiar Configuración de Odoo

**Archivo**: `setup_odoo_complete.sh` (sección 5)

```bash
# Modificar la sección que crea odoo.conf
cat > /efs/HELIPISTAS-ODOO-17/odoo/conf/odoo.conf << EOF
[options]
# TUS CAMBIOS AQUÍ
workers = 4  # Ejemplo: aumentar workers
EOF
```

Luego:
1. Subir cambios a GitHub
2. Ejecutar `terraform destroy && terraform apply`

#### Cambiar Configuración de Nginx

**Archivo**: `setup_odoo_complete.sh` (sección 6 y 9)

Modificar las secciones que crean `nginx/conf/default.conf`

#### Agregar Módulos Custom de Odoo

```bash
# Conectarse a la instancia
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Copiar módulos a EFS
sudo cp -r /ruta/a/modulos/* /efs/HELIPISTAS-ODOO-17/odoo/addons/

# Reiniciar Odoo para que detecte los módulos
cd /efs/HELIPISTAS-ODOO-17
docker-compose restart helipistas_odoo
```

#### Cambiar Versión de Odoo

**Archivo**: `setup_odoo_complete.sh` (sección 2)

```bash
# Cambiar en docker-compose.yml
helipistas_odoo:
  image: odoo:18  # Cambiar versión
```

⚠️ **ADVERTENCIA**: Cambiar versiones puede requerir migraciones de base de datos.

---

## 📞 Soporte y Contacto

### Repositorio GitHub
- **URL**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts
- **Issues**: Para reportar bugs o solicitar features

### Recursos de Odoo
- **Documentación oficial**: https://www.odoo.com/documentation/17.0/
- **Foros**: https://www.odoo.com/forum

### Recursos de AWS
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS EFS**: https://docs.aws.amazon.com/efs/
- **AWS EC2**: https://docs.aws.amazon.com/ec2/

---

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia MIT. Ver archivo `LICENSE` para más detalles.

---

## 🎯 Resumen Ejecutivo para Nuevos Desarrolladores

### ¿Qué hace este proyecto?

Despliega automáticamente un servidor Odoo 17 completo en AWS con:
- Infraestructura definida en Terraform
- Datos persistentes en EFS
- SSL automático con Let's Encrypt
- Todo en contenedores Docker

### ¿Cómo funciona?

1. **Terraform** crea una instancia EC2 y configura red
2. **user_data_simple.sh** prepara el sistema (Docker, EFS)
3. **setup_odoo_complete.sh** configura servicios y SSL
4. Resultado: Odoo funcionando en https://erp17.helipistas.com

### ¿Cómo despliego?

```bash
cd terraform
terraform init
terraform destroy -auto-approve && terraform apply -auto-approve
# Esperar 10-12 minutos
# Listo: https://erp17.helipistas.com
```

### ¿Dónde están los datos?

Todo en EFS (`fs-ec7152d9`):
- Base de datos: `/efs/HELIPISTAS-ODOO-17/postgres/`
- Archivos Odoo: `/efs/HELIPISTAS-ODOO-17/odoo/`
- Certificados SSL: `/efs/HELIPISTAS-ODOO-17/certbot/`

### ¿Cómo modifico algo?

1. Editar `setup_odoo_complete.sh` en el repo
2. Subir cambios a GitHub
3. Ejecutar `terraform destroy && terraform apply`
4. El script actualizado se descarga automáticamente

### ¿Cómo accedo al servidor?

```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
cd /efs/HELIPISTAS-ODOO-17
docker-compose ps
```

---

**¡Bienvenido al proyecto! Este README debería tener todo lo que necesitas para entender, desplegar y evolucionar la infraestructura de Helipistas Odoo 17.** 🚀
