# Deployment con Spot Instances - Odoo 17 ERP

## 📋 Descripción

Deployment automatizado de Odoo 17 usando **AWS Spot Instances** con **auto-recovery garantizado**. 

### ✨ Características Principales

- 💰 **~70% más barato** que On-Demand (~$9/mes vs $30/mes)
- 🔄 **Auto-recovery automático** tras terminación de AWS
- 📦 **Persistencia de datos** en EFS (sobrevive terminaciones)
- 🌐 **DNS dinámico** con actualización automática (Route 53)
- 🔒 **SSL automático** con Let's Encrypt (DNS challenge)
- 📊 **Monitoreo de terminación** con apagado graceful
- ⚡ **Downtime mínimo**: 2-3 minutos durante recreación

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────┐
│ AWS Spot Request (persistent)                           │
│   - Auto-recovery tras terminación                      │
│   - Válido hasta 2026-12-31                             │
│   - Precio máximo: configurable (null = on-demand)      │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ EC2 Spot Instance (t3.medium)                           │
│   - IP pública dinámica (cambia en cada recreación)     │
│   - user_data_spot.sh: Bootstrap mínimo                 │
│   - setup.sh: Configuración completa (desde GitHub)     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ Almacenamiento                                          │
│   - EFS (fs-ec7152d9): Datos persistentes               │
│   - EBS (opcional): Logs/caché temporal                 │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ Docker Compose                                          │
│   - PostgreSQL 15: Base de datos                        │
│   - Odoo 17: Aplicación                                 │
│   - Nginx: Proxy reverso + SSL                          │
│   - Certbot: Renovación automática SSL                  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│ DNS Dinámico (Route 53)                                 │
│   dev.helipistas.com → IP actual                        │
│   - Se actualiza automáticamente en cada recreación     │
└─────────────────────────────────────────────────────────┘
```

---

## 🔄 Flujo de Auto-Recovery

### Deployment Inicial
```bash
terraform apply
  ↓
AWS asigna Spot Instance (IP: 3.250.15.42)
  ↓
user_data_spot.sh: Bootstrap mínimo
  ↓
setup.sh descargado desde GitHub
  ↓
- Instala Docker, EFS utils, AWS CLI
- Monta EFS y EBS
- Descarga docker-compose.yml y configs
- Actualiza DNS: dev.helipistas.com → 3.250.15.42
- Obtiene certificado SSL
- Inicia servicios
- Instala spot-termination-handler
  ↓
✅ Sistema operativo (~3 min)
```

### AWS Termina la Instancia
```bash
Metadata endpoint: aviso 2 min antes
  ↓
spot-termination-handler detecta aviso
  ↓
docker-compose down --timeout 60 (apagado graceful)
  ↓
EFS desmonta correctamente
  ↓
AWS termina EC2
  ↓
⏳ DOWNTIME (2-3 min)
```

### Auto-Recovery Automático
```bash
Spot Request detecta terminación
  ↓
AWS asigna NUEVA Spot Instance (IP: 54.194.23.89)
  ↓
user_data_spot.sh se ejecuta automáticamente
  ↓
setup.sh se descarga y ejecuta
  ↓
- Monta EFS → DATOS INTACTOS
- Detecta nueva IP
- Actualiza DNS: dev.helipistas.com → 54.194.23.89
- Levanta servicios
  ↓
✅ Sistema recuperado (~3 min)
```

---

## 📂 Estructura de Archivos

```
deployments/spot/
├── README.md                          # Este archivo
│
├── terraform/                         # Infraestructura como código
│   ├── main-spot.tf                   # Spot Request, Security Group, IAM
│   ├── variables-spot.tf              # Variables configurables
│   ├── terraform.tfvars.example       # Ejemplo de configuración
│   └── user_data_spot.sh              # Bootstrap mínimo (~30 líneas)
│
├── setup.sh                           # ⚠️ CRÍTICO - Descargado desde GitHub
│                                      # Toda la lógica de configuración
│
├── docker-compose.yml                 # Template de servicios
├── nginx.conf                         # Configuración base Nginx
├── default.conf.template              # Template de vhost Nginx
└── odoo.conf.template                 # Template de configuración Odoo
```

---

## 🚀 Guía de Deployment

### 1. Prerrequisitos

- AWS CLI configurado
- Terraform instalado
- Llave SSH (ERP.pem)
- Zona de Route 53 configurada
- EFS existente (o crear uno nuevo)

### 2. Configuración

```bash
cd deployments/spot/terraform/

# Copiar ejemplo de variables
cp terraform.tfvars.example terraform.tfvars

# Editar con tus valores
nano terraform.tfvars
```

**Variables críticas a configurar**:
```hcl
# Tu IP para SSH
allowed_ssh_cidr = "1.2.3.4/32"

# Route 53
route53_zone_id = "Z0XXXXXXXXXX"

# PostgreSQL (NUNCA hacer commit)
postgres_password = "STRONG_PASSWORD_HERE"

# EFS (usar existente o crear nuevo)
efs_id = "fs-ec7152d9"

# Dominio
domain_name = "dev.helipistas.com"
```

### 3. Deployment

```bash
# Inicializar Terraform
terraform init

# Ver plan
terraform plan

# Aplicar
terraform apply
```

### 4. Verificación

```bash
# Ver outputs
terraform output

# Conectar por SSH
ssh -i ~/.ssh/ERP.pem ec2-user@<IP>

# Ver logs de setup
tail -f /var/log/setup.log

# Ver servicios
docker-compose ps

# Ver logs de servicios
docker-compose logs -f
```

### 5. Acceso

- **URL**: https://dev.helipistas.com
- **Admin Odoo**: Ver `/root/odoo_admin_password.txt` en la instancia

---

## ⚙️ Variables Configurables

### Infraestructura

| Variable | Descripción | Default | Notas |
|----------|-------------|---------|-------|
| `instance_type` | Tipo de EC2 | `t3.medium` | t3.small (más barato), t3.large (más potente) |
| `spot_max_price` | Precio máximo/hora | `null` | null = pagar hasta on-demand (siempre disponible) |
| `spot_valid_until` | Expiración request | `2026-12-31` | Spot Request se cancela después |
| `root_volume_size` | Tamaño root EBS | `20` GB | Sistema operativo |

### Almacenamiento

| Variable | Descripción | Default | Notas |
|----------|-------------|---------|-------|
| `efs_id` | ID del EFS | `fs-ec7152d9` | Cambiar para usar otro EFS |
| `efs_mount_point` | Punto de montaje | `/efs/HELIPISTAS-ODOO-17-DEV` | Carpeta en la instancia |
| `ebs_volume_size` | Tamaño EBS adicional | `0` GB | 0 = no crear, >0 = crear volumen |
| `ebs_skip_destroy` | Mantener EBS al destruir | `true` | Protege datos |

### Aplicación

| Variable | Descripción | Default | Notas |
|----------|-------------|---------|-------|
| `domain_name` | Dominio | `dev.helipistas.com` | Debe existir en Route 53 |
| `route53_zone_id` | ID zona Route 53 | - | **REQUERIDO** |
| `postgres_password` | Contraseña DB | - | **REQUERIDO** (secret) |
| `odoo_workers` | Workers Odoo | `2` | 0 = dev, 2 = prod (t3.medium) |

---

## 🔐 Seguridad

### Secrets

- `postgres_password`: En terraform.tfvars (NO en Git)
- `odoo_admin_password`: Generada automáticamente, guardada en `/root/odoo_admin_password.txt`
- Claves SSH: Nunca hacer commit de `.pem`

### Firewall (Security Group)

| Puerto | Servicio | Origen |
|--------|----------|--------|
| 22 | SSH | Tu IP específica |
| 80 | HTTP | 0.0.0.0/0 (redirige a HTTPS) |
| 443 | HTTPS | 0.0.0.0/0 |
| 2049 | NFS (EFS) | VPC interna |
| 8069 | Odoo | ❌ Bloqueado (solo via Nginx) |

### IAM Permissions

La instancia tiene permisos para:
- ✅ Leer/escribir EFS
- ✅ Actualizar Route 53
- ✅ Escribir logs a CloudWatch
- ❌ No tiene acceso a otros recursos AWS

---

## 🛠️ Operaciones Comunes

### Ver logs

```bash
# SSH a la instancia
ssh -i ~/.ssh/ERP.pem ec2-user@<IP>

# Logs de setup
tail -f /var/log/setup.log

# Logs de user data
tail -f /var/log/user-data.log

# Logs de Docker Compose
cd /efs/HELIPISTAS-ODOO-17-DEV
docker-compose logs -f

# Logs de Odoo específicamente
docker-compose logs -f odooApp

# Logs de PostgreSQL
docker-compose logs -f postgresOdoo17
```

### Reiniciar servicios

```bash
cd /efs/HELIPISTAS-ODOO-17-DEV

# Reiniciar todo
docker-compose restart

# Reiniciar un servicio
docker-compose restart odooApp

# Apagar y volver a levantar
docker-compose down
docker-compose up -d
```

### Actualizar configuración

Como `setup.sh` se descarga de GitHub, puedes:

1. Modificar `setup.sh` en el repositorio
2. Push a GitHub
3. Recrear la instancia: `terraform apply -replace=aws_spot_instance_request.odoo_spot`

### Ver estado del Spot Termination Handler

```bash
# Ver estado
systemctl status spot-termination-handler

# Ver logs
journalctl -u spot-termination-handler -f

# Ver log de terminaciones
tail -f /var/log/spot-termination.log
```

---

## 🐛 Troubleshooting

### Spot Instance no se crea

**Síntoma**: `terraform apply` espera indefinidamente

**Diagnóstico**:
```bash
# Ver estado del Spot Request en AWS Console
# O con AWS CLI:
aws ec2 describe-spot-instance-requests
```

**Causas comunes**:
- Precio máximo muy bajo (si configuraste `spot_max_price`)
- No hay capacidad en la zona de disponibilidad
- Límite de Spot Instances alcanzado

**Solución**:
```hcl
# En terraform.tfvars, cambiar a precio on-demand
spot_max_price = null  # Paga hasta on-demand
```

### DNS no se actualiza

**Síntoma**: `dev.helipistas.com` no resuelve a la nueva IP

**Diagnóstico**:
```bash
# Ver logs de setup
grep "Actualizando DNS" /var/log/setup.log

# Verificar permisos IAM
aws iam get-role-policy --role-name odoo-spot-instance-role --policy-name route53-update-policy
```

**Causas comunes**:
- `route53_zone_id` incorrecto
- IAM role sin permisos Route 53
- TTL alto (esperar 60 segundos)

**Solución**:
```bash
# Obtener Zone ID correcto
aws route53 list-hosted-zones

# Actualizar manualmente
INSTANCE_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
aws route53 change-resource-record-sets --hosted-zone-id Z0XXXX \
  --change-batch '{"Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"dev.helipistas.com","Type":"A","TTL":60,"ResourceRecords":[{"Value":"'$INSTANCE_IP'"}]}}]}'
```

### SSL no funciona

**Síntoma**: "Certificate not found" o conexión no segura

**Diagnóstico**:
```bash
# Ver logs de certbot
docker logs certbot_spot

# Verificar archivos de certificado
ls -la /efs/HELIPISTAS-ODOO-17-DEV/certbot/conf/live/dev.helipistas.com/
```

**Causas comunes**:
- DNS no apunta a la IP correcta (certbot falla challenge)
- IAM role sin permisos Route 53 (para DNS challenge)
- Dominio no válido

**Solución**:
```bash
# Obtener certificado manualmente
docker run --rm \
  -v /efs/HELIPISTAS-ODOO-17-DEV/certbot/conf:/etc/letsencrypt \
  --env AWS_DEFAULT_REGION=eu-west-1 \
  certbot/dns-route53 certonly \
  --dns-route53 \
  --non-interactive \
  --agree-tos \
  --email admin@helipistas.com \
  --domains dev.helipistas.com

# Reiniciar nginx
docker-compose restart nginx
```

### EFS no monta

**Síntoma**: "mount.nfs4: Connection timed out"

**Diagnóstico**:
```bash
# Ver logs
grep "Montando EFS" /var/log/setup.log

# Verificar conectividad
ping -c 3 fs-ec7152d9.efs.eu-west-1.amazonaws.com
```

**Causas comunes**:
- Security Group no permite puerto 2049
- EFS ID incorrecto
- Instancia en zona de disponibilidad diferente

**Solución**:
```bash
# Montar manualmente
mount -t efs -o tls fs-ec7152d9:/ /efs/HELIPISTAS-ODOO-17-DEV

# Verificar
df -h | grep efs
```

### Servicios no arrancan

**Síntoma**: `docker-compose ps` muestra servicios "exited"

**Diagnóstico**:
```bash
cd /efs/HELIPISTAS-ODOO-17-DEV
docker-compose logs
```

**Causas comunes**:
- Contraseña de PostgreSQL incorrecta
- Permisos en directorios EFS
- Falta espacio en disco

**Solución**:
```bash
# Verificar .env
cat .env

# Verificar permisos
ls -la /efs/HELIPISTAS-ODOO-17-DEV/

# Corregir permisos
chown -R 101:101 /efs/HELIPISTAS-ODOO-17-DEV/postgres
chown -R 101:101 /efs/HELIPISTAS-ODOO-17-DEV/odoo

# Reiniciar
docker-compose down
docker-compose up -d
```

---

## 📊 Monitoreo

### Verificar si Spot va a ser terminada

```bash
# Verificar metadata endpoint
curl -s http://169.254.169.254/latest/meta-data/spot/termination-time

# Si devuelve 200: Terminación inminente (2 min)
# Si devuelve 404: Todo OK
```

### Ver estado del Spot Request

```bash
aws ec2 describe-spot-instance-requests \
  --filters "Name=state,Values=active" \
  --query 'SpotInstanceRequests[0].{Status:Status.Code,Instance:InstanceId,Price:ActualBlockHourlyPrice}'
```

### Logs de terminaciones previas

```bash
# Ver todas las terminaciones
cat /var/log/spot-termination.log

# Ver última
tail -n 20 /var/log/spot-termination.log
```

---

## 💰 Costos

### Comparativa On-Demand vs Spot

| Concepto | On-Demand | Spot | Ahorro |
|----------|-----------|------|--------|
| **EC2 t3.medium** | $0.0416/h | ~$0.0125/h | 70% |
| **EFS** | Variable | Variable | - |
| **EBS (si se usa)** | $0.10/GB/mes | $0.10/GB/mes | - |
| **Data Transfer** | Según uso | Según uso | - |
| **TOTAL (~720h/mes)** | ~$30/mes | ~$9/mes | **$21/mes** |

**Nota**: Precios aproximados para eu-west-1. Verificar en [AWS Pricing](https://aws.amazon.com/ec2/spot/pricing/).

### Optimización de Costos

1. **Usar t3.small** si no necesitas 2 vCPUs: ~$4.5/mes
2. **EBS = 0** si EFS es suficiente
3. **Spot price = null** para garantizar disponibilidad (paga hasta on-demand)
4. **Apagar en horario no laboral** (requiere programación adicional)

---

## 🔄 Diferencias vs On-Demand

| Aspecto | On-Demand | Spot |
|---------|-----------|------|
| **Costo** | ~$30/mes | ~$9/mes |
| **IP** | Elastic IP fija | Dinámica (cambia) |
| **DNS** | Estático | Dinámico (Route 53) |
| **Uptime** | 99.9%+ | 95-98% (interrupciones) |
| **SSL** | HTTP challenge | DNS challenge |
| **Terminación** | Manual | Automática (AWS) |
| **Recovery** | Manual | Automático |
| **Downtime** | 0 (si no falla) | 2-3 min (en interrupciones) |
| **Uso** | Producción | Desarrollo/Staging |

---

## 📝 Mantenimiento

### Actualizar Docker Compose

```bash
cd /efs/HELIPISTAS-ODOO-17-DEV

# Descargar nueva versión desde GitHub
wget -O docker-compose.yml https://raw.githubusercontent.com/leulit/.../deployments/spot/docker-compose.yml

# Recrear servicios
docker-compose up -d --force-recreate
```

### Backup Manual

```bash
# Backup de PostgreSQL
docker exec postgres_odoo17_spot pg_dumpall -U odoo > /root/backup_$(date +%Y%m%d).sql

# Copiar a S3 (opcional)
aws s3 cp /root/backup_*.sql s3://my-backups/odoo/
```

### Renovar SSL Manualmente

```bash
docker run --rm \
  -v /efs/HELIPISTAS-ODOO-17-DEV/certbot/conf:/etc/letsencrypt \
  --env AWS_DEFAULT_REGION=eu-west-1 \
  certbot/dns-route53 renew

docker-compose restart nginx
```

---

## 🎯 Mejores Prácticas

### ✅ DO

- Usar `spot_max_price = null` para producción (garantiza disponibilidad)
- Monitorear logs regularmente
- Hacer backups de PostgreSQL periódicamente
- Probar recreación de instancia regularmente
- Verificar que auto-recovery funciona

### ❌ DON'T

- No hardcodear secrets en archivos versionados
- No usar solo EBS (se pierde en terminación)
- No exponer Odoo directamente (siempre via Nginx)
- No asumir IP fija (cambiar código si depende de IP)
- No ignorar avisos de terminación (logs)

---

## 🆘 Soporte

### Logs Críticos

```bash
/var/log/setup.log              # Setup completo
/var/log/user-data.log          # Bootstrap
/var/log/spot-termination.log   # Terminaciones
```

### Comandos Útiles

```bash
# Ver IP actual
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Ver Spot Request status
aws ec2 describe-spot-instance-requests --spot-instance-request-ids sir-XXXX

# Forzar recreación
terraform apply -replace=aws_spot_instance_request.odoo_spot

# Destruir todo
terraform destroy
```

---

## 📚 Referencias

- [AWS Spot Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-spot-instances.html)
- [Spot Instance Interruptions](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-interruptions.html)
- [Persistent Spot Requests](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/spot-requests.html#persistent-spot-request)
- [Let's Encrypt DNS Challenge](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)

---

**Última actualización**: 19 Noviembre 2025  
**Versión**: 1.0  
**Mantenedor**: @leulit
