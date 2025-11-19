# 🚀 Despliegue On-Demand - Helipistas Odoo 17

Este es el **despliegue documentado y en producción** del proyecto Helipistas Odoo 17.

## 📋 Descripción

Este deployment utiliza **instancias EC2 On-Demand** de AWS para garantizar disponibilidad continua y predecible.

### ✅ Características

- **Tipo de instancia**: EC2 On-Demand (t3.medium)
- **Disponibilidad**: 100% garantizada por AWS
- **Costos**: Predecibles, sin interrupciones
- **Elastic IP**: Fija, no cambia nunca
- **Ideal para**: Producción estable

---

## 📁 Contenido de esta Carpeta

```
deployments/on-demand/
├── README.md                    ← Este archivo
├── setup_odoo_complete.sh       ← Script de configuración completa
└── terraform/                   ← Infraestructura como código
    ├── main-simple.tf           ← Configuración principal de Terraform
    ├── variables-simple.tf      ← Variables de Terraform
    ├── outputs-simple.tf        ← Outputs de Terraform
    ├── terraform.tfvars         ← Valores de variables (NO EN GIT)
    ├── terraform.tfvars.example ← Ejemplo de valores
    ├── user_data_simple.sh      ← Script de inicialización EC2
    └── ...                      ← Otros archivos de soporte
```

---

## 🎯 Cómo Desplegar

### 1. Prerrequisitos

- **Terraform** instalado (>= 1.0)
- **AWS CLI** configurado con credenciales
- **Acceso SSH** a AWS (clave PEM)
- **Recursos AWS existentes**:
  - EFS: `fs-ec7152d9`
  - Elastic IP: `eipalloc-0184418cc26d4e66f`
  - VPC: `vpc-92d074f6`
  - Subnet: `subnet-c362e2a7`
  - Security Group: Será creado por Terraform

### 2. Configurar Variables

Copia el archivo de ejemplo:

```bash
cd deployments/on-demand/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edita `terraform.tfvars` con tus valores:

```hcl
# Contraseñas
postgres_password      = "tu_password_postgres"
odoo_master_password   = "tu_password_odoo"

# Dominio
domain_name            = "erp17.helipistas.com"

# Recursos AWS (normalmente no cambiar)
efs_id                 = "fs-ec7152d9"
elastic_ip_allocation  = "eipalloc-0184418cc26d4e66f"
vpc_id                 = "vpc-92d074f6"
subnet_id              = "subnet-c362e2a7"

# EC2 (normalmente no cambiar)
instance_type          = "t3.medium"
ami_id                 = "ami-0d71ea30463e0ff8d"  # Amazon Linux 2
```

### 3. Desplegar

```bash
cd deployments/on-demand/terraform

# Inicializar Terraform
terraform init

# Ver plan de despliegue
terraform plan

# Aplicar (desplegar)
terraform apply
```

**Tiempo estimado**: 10-12 minutos

### 4. Verificar

Una vez completado:

```bash
# Ver IP pública
terraform output instance_public_ip

# Conectarse por SSH
ssh -i /path/to/ERP.pem ec2-user@<IP>

# Ver logs de despliegue
ssh -i /path/to/ERP.pem ec2-user@<IP> "sudo tail -f /var/log/user-data.log"
```

Acceder a Odoo:
- **URL**: https://erp17.helipistas.com
- **Usuario**: admin
- **Password**: El que configuraste en `odoo_master_password`

---

## 🔧 Gestión Diaria

### Conectarse a la Instancia

```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
```

### Ver Logs

```bash
# Logs de Docker Compose
docker-compose logs -f

# Logs de Odoo
docker-compose logs -f odoo

# Logs de Nginx
docker-compose logs -f nginx

# Logs de despliegue inicial
sudo tail -f /var/log/user-data.log
```

### Reiniciar Servicios

```bash
cd /efs/HELIPISTAS-ODOO-17

# Reiniciar todos los servicios
docker-compose restart

# Reiniciar solo Odoo
docker-compose restart odoo

# Ver estado
docker-compose ps
```

### Backup Manual

```bash
# Backup de PostgreSQL
docker exec odoo-postgres pg_dump -U odoo odoo > backup_$(date +%Y%m%d).sql

# Backup de filestore
tar -czf filestore_backup_$(date +%Y%m%d).tar.gz /efs/HELIPISTAS-ODOO-17/odoo/filestore/
```

---

## 🏗️ Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                         INTERNET                            │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ HTTPS (443)
                       │
                  ┌────▼─────┐
                  │ Route 53 │
                  │ DNS      │
                  └────┬─────┘
                       │
                       │ erp17.helipistas.com → 54.228.16.152
                       │
        ┌──────────────▼───────────────┐
        │      Elastic IP (Fija)       │
        │   eipalloc-0184418cc26d4e66f │
        └──────────────┬───────────────┘
                       │
        ┌──────────────▼───────────────┐
        │   EC2 Instance (On-Demand)   │
        │         t3.medium            │
        │     Amazon Linux 2           │
        │                              │
        │  ┌────────────────────────┐  │
        │  │   Docker Compose       │  │
        │  │  ┌──────────────────┐  │  │
        │  │  │  Nginx (Proxy)   │  │  │
        │  │  │   + Certbot SSL  │  │  │
        │  │  └────────┬─────────┘  │  │
        │  │           │            │  │
        │  │  ┌────────▼─────────┐  │  │
        │  │  │   Odoo 17        │  │  │
        │  │  │  (Port 8069)     │  │  │
        │  │  └────────┬─────────┘  │  │
        │  │           │            │  │
        │  │  ┌────────▼─────────┐  │  │
        │  │  │  PostgreSQL 15   │  │  │
        │  │  │   (Port 5432)    │  │  │
        │  │  └──────────────────┘  │  │
        │  └────────────────────────┘  │
        └──────────────┬───────────────┘
                       │
                       │ NFS 4.1
                       │
        ┌──────────────▼───────────────┐
        │      EFS (Persistencia)      │
        │        fs-ec7152d9           │
        │                              │
        │  /efs/HELIPISTAS-ODOO-17/    │
        │  ├── postgres/               │
        │  ├── odoo/filestore/         │
        │  ├── odoo/conf/              │
        │  ├── nginx/ssl/              │
        │  └── certbot/conf/           │
        └──────────────────────────────┘
```

---

## 💰 Costos Estimados

### EC2 On-Demand (t3.medium)

- **Región**: eu-west-1 (Irlanda)
- **Precio**: ~$0.0416/hora
- **Mensual**: ~$30.37/mes (24/7)
- **Anual**: ~$364.42/año

### Otros Recursos

- **EFS**: ~$0.30/GB/mes (variable según uso)
- **Elastic IP**: Gratis mientras esté asociada
- **Tráfico**: Primeros 100GB/mes gratis

**Total estimado**: ~$40-50/mes (incluyendo EFS)

---

## 🆚 Comparación con Spot Instances

| Característica | On-Demand (Esta carpeta) | Spot (../spot/) |
|----------------|-------------------------|-----------------|
| **Disponibilidad** | 100% garantizada | ~95% (puede interrumpirse) |
| **Costo** | ~$30/mes | ~$9-12/mes (70% descuento) |
| **Elastic IP** | Fija (no cambia) | Cambia en cada nueva instancia |
| **Ideal para** | Producción estable | Desarrollo, staging |
| **Complejidad** | Baja | Media (manejo de interrupciones) |
| **Tiempo setup** | 10-12 min | 10-12 min |

---

## 📚 Documentación Relacionada

### En el Repositorio Principal

- **Documentación completa**: `../../README-COMPLETO.md`
- **Guía rápida**: `../../GUIA-RAPIDA.md`
- **Guía desarrolladores**: `../../GUIA-DESARROLLADORES.md`
- **Decisiones arquitectura**: `../../DECISIONES-ARQUITECTURA.md`
- **Índice documentación**: `../../INDICE-DOCUMENTACION.md`

### Archivos Clave en Esta Carpeta

- **`terraform/main-simple.tf`**: Configuración Terraform de la EC2 On-Demand
- **`terraform/user_data_simple.sh`**: Script de inicialización de la instancia
- **`setup_odoo_complete.sh`**: Configuración completa de Odoo, Docker, SSL

---

## 🔐 Seguridad

### Security Group

El Security Group permite:

- **SSH (22)**: Solo desde tu IP
- **HTTP (80)**: Desde cualquier IP (redirige a HTTPS)
- **HTTPS (443)**: Desde cualquier IP
- **Odoo (8069)**: BLOQUEADO externamente (solo a través de Nginx)

### SSL/TLS

- **Proveedor**: Let's Encrypt
- **Renovación**: Automática cada 60 días
- **Calificación**: A+ en SSL Labs

### Secrets

❌ **NUNCA** subir a Git:
- `terraform.tfvars` (contiene contraseñas)
- Archivos `.pem` (claves SSH)

✅ **SÍ** subir:
- `terraform.tfvars.example` (sin valores reales)

---

## 🐛 Troubleshooting

### Problema: Terraform falla en `apply`

**Solución**:
```bash
terraform destroy
terraform apply
```

### Problema: Odoo no arranca

**Diagnóstico**:
```bash
ssh -i /path/to/ERP.pem ec2-user@<IP>
docker-compose logs odoo
```

**Causas comunes**:
- PostgreSQL no está listo (esperar 1-2 min)
- Error en contraseñas
- Falta espacio en disco

### Problema: SSL no funciona

**Verificar**:
```bash
ssh -i /path/to/ERP.pem ec2-user@<IP>
docker-compose logs certbot
```

**Causas comunes**:
- DNS no apunta a IP correcta
- Firewall bloquea puerto 80
- Dominio no válido

### Problema: No puedo conectarme por SSH

**Verificar**:
1. Security Group permite SSH desde tu IP
2. Ruta correcta al archivo `.pem`
3. Permisos del archivo `.pem`: `chmod 400 ERP.pem`

---

## 🔄 Destruir Infraestructura

Si necesitas eliminar todo:

```bash
cd deployments/on-demand/terraform
terraform destroy
```

⚠️ **ADVERTENCIA**: Esto eliminará:
- La instancia EC2
- El Security Group
- La asociación de Elastic IP

❌ **NO** eliminará (recursos existentes reutilizados):
- EFS (`fs-ec7152d9`)
- Elastic IP (`eipalloc-0184418cc26d4e66f`)
- VPC (`vpc-92d074f6`)
- Subnet (`subnet-c362e2a7`)

**Los datos en EFS se mantendrán** y podrás redesplegar cuando quieras.

---

## 📞 Soporte

Para más información, consulta:

1. **Documentación principal**: `../../INDICE-DOCUMENTACION.md`
2. **Guía rápida**: `../../GUIA-RAPIDA.md`
3. **Issues GitHub**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/issues

---

**✅ Este es el despliegue en producción documentado y probado.**

Para deployment con Spot Instances (desarrollo/staging), ver: `../spot/README.md`
