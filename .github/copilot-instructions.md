# Copilot Instructions - Helipistas Odoo 17 ERP

## 📋 Contexto del Proyecto

Este es un proyecto de **Infrastructure as Code (IaC)** para desplegar **Odoo 17 ERP** en **AWS** usando **Terraform**, con persistencia en **EFS**, **SSL automático** con Let's Encrypt, y arquitectura basada en **Docker Compose**.

### Objetivo Principal

Proporcionar deployments automatizados de Odoo 17 con dos modalidades:
- **On-Demand**: Producción (100% disponibilidad, IP fija, ~$30/mes)
- **Spot Instances**: Desarrollo/Staging (70% ahorro, IP dinámica, ~$9/mes)

---

## 🏗️ Arquitectura del Sistema

### Stack Tecnológico

```
Internet → Route 53 (DNS) → Elastic IP → EC2 Instance
                                          ├── Docker: Nginx (Proxy + SSL)
                                          ├── Docker: Odoo 17
                                          └── Docker: PostgreSQL 15
                                               └── Datos persistentes en EFS
```

### Componentes Clave

1. **Terraform** (v4.67.0): Provisiona infraestructura AWS
2. **AWS EC2** (t3.medium, Amazon Linux 2): Servidor de aplicación
3. **AWS EFS** (fs-ec7152d9): Almacenamiento persistente compartido
4. **Elastic IP** (eipalloc-0184418cc26d4e66f): IP fija para producción
5. **Docker Compose**: Orquesta contenedores (Nginx, Odoo, PostgreSQL)
6. **Let's Encrypt**: SSL/TLS automático con renovación
7. **VPC existente** (vpc-92d074f6, subnet-c362e2a7): Reutilizada

---

## 📂 Estructura del Proyecto

```
helipistas-erp-odoo-17-server-scripts/
├── README.md                           # Documentación principal
├── setup_odoo_complete.sh              # ⚠️ CRÍTICO: Se descarga desde GitHub
│
├── deployments/                        # Tipos de deployment
│   ├── README.md                       # Comparativa On-Demand vs Spot
│   ├── on-demand/                      # Producción (EC2 On-Demand)
│   │   ├── README.md
│   │   ├── setup_odoo_complete.sh      # Copia del script raíz
│   │   └── terraform/
│   │       ├── main-simple.tf          # Configuración principal
│   │       ├── user_data_simple.sh     # Script de inicialización EC2
│   │       ├── variables-simple.tf
│   │       ├── outputs-simple.tf
│   │       ├── terraform.tfvars.example
│   │       └── .terraform.lock.hcl
│   │
│   └── spot/                           # Desarrollo (EC2 Spot - futuro)
│       └── README.md
│
└── docs/                               # Documentación completa
    ├── INDICE-DOCUMENTACION.md         # Navegación por documentos
    ├── README-COMPLETO.md              # Referencia técnica
    ├── GUIA-RAPIDA.md                  # Comandos diarios
    ├── GUIA-DESARROLLADORES.md         # Para developers
    ├── DECISIONES-ARQUITECTURA.md      # ADR (Architecture Decisions)
    ├── RESUMEN-EJECUTIVO.md            # Visión general
    └── ... (otros docs)
```

---

## ⚠️ Archivos Críticos

### `setup_odoo_complete.sh` (RAÍZ)

**Ubicación**: `/setup_odoo_complete.sh`

**Importancia**: **CRÍTICA** - No mover ni eliminar

**Razón**: 
- Se descarga desde GitHub durante el deployment por `user_data_simple.sh`
- URL: `https://raw.githubusercontent.com/leulit/.../main/setup_odoo_complete.sh`
- La EC2 lo ejecuta automáticamente al arrancar

**Funciones**:
1. Corrige permisos para contenedores Docker
2. Genera `docker-compose.yml` dinámicamente
3. Crea configuraciones de Nginx y Odoo
4. Obtiene certificados SSL con certbot
5. Inicia todos los servicios

### `deployments/on-demand/terraform/user_data_simple.sh`

**Línea crítica 150**:
```bash
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/.../main/setup_odoo_complete.sh
```

**Si modificas la ubicación de `setup_odoo_complete.sh`**, DEBES actualizar esta URL.

---

## 🔑 Recursos AWS Reutilizados

**NO se crean con Terraform** (ya existen):

| Recurso | ID | Propósito |
|---------|-----|-----------|
| **EFS** | `fs-ec7152d9` | Almacenamiento persistente |
| **Elastic IP** | `eipalloc-0184418cc26d4e66f` | IP fija (54.228.16.152) |
| **VPC** | `vpc-92d074f6` | Red virtual |
| **Subnet** | `subnet-c362e2a7` | Subred |

**Se crean con Terraform**:
- EC2 Instance
- Security Group (puertos 22, 80, 443)
- Asociación de Elastic IP

---

## 🚀 Flujo de Deployment

### 1. Terraform Apply (Local)

```bash
cd deployments/on-demand/terraform
terraform init
terraform apply
```

**Crea**:
- EC2 instance (t3.medium)
- Security Group
- Asocia Elastic IP
- Inyecta `user_data_simple.sh`

### 2. EC2 Boot (AWS)

**Script**: `user_data_simple.sh` se ejecuta automáticamente

**Pasos**:
1. Actualiza sistema e instala dependencias (Docker, EFS utils, AWS CLI)
2. Configura Docker
3. Instala Docker Compose
4. Monta EFS en `/efs` (NFS4)
5. Crea estructura de directorios en `/efs/HELIPISTAS-ODOO-17/`
6. **Descarga `setup_odoo_complete.sh` desde GitHub**
7. Ejecuta `setup_odoo_complete.sh` con parámetros

### 3. Setup Completo (AWS)

**Script**: `setup_odoo_complete.sh` (descargado)

**Pasos**:
1. Corrige permisos para UIDs de Docker (101, 999)
2. Genera `docker-compose.yml` con volúmenes EFS
3. Crea configuración de Odoo (`odoo.conf`)
4. Crea configuración de Nginx (proxy reverso)
5. Inicia contenedores PostgreSQL y Odoo
6. Espera a que Odoo esté disponible
7. Obtiene certificado SSL con certbot
8. Reinicia Nginx con SSL
9. Sistema listo

**Tiempo total**: 10-12 minutos

---

## 📁 Datos Persistentes en EFS

### Estructura en `/efs/HELIPISTAS-ODOO-17/`

```
/efs/HELIPISTAS-ODOO-17/
├── postgres/                   # Base de datos PostgreSQL
│   └── (datos de PostgreSQL)
├── odoo/
│   ├── conf/                   # odoo.conf
│   ├── addons/                 # Módulos custom
│   ├── filestore/              # Archivos subidos por usuarios
│   └── sessiones/              # Sesiones de Odoo
├── nginx/
│   ├── conf/                   # nginx.conf
│   └── ssl/                    # Certificados (no usado, usa certbot/)
└── certbot/
    ├── conf/                   # Certificados Let's Encrypt
    └── www/                    # Challenge ACME
```

**Persistencia**: Los datos sobreviven a la destrucción/recreación de la EC2

---

## 🔐 Secretos y Seguridad

### Archivos con Secrets (NO en Git)

- `deployments/on-demand/terraform/terraform.tfvars`
- Claves `.pem` (SSH)
- Archivos `.env`

### `.gitignore` protege:

```gitignore
*.tfstate
*.tfstate.*
terraform.tfvars
**/terraform.tfvars
.env
*.pem
*.key
```

### Security Group

**Puertos abiertos**:
- **22 (SSH)**: Solo desde IP específica
- **80 (HTTP)**: Desde cualquier IP (redirige a HTTPS)
- **443 (HTTPS)**: Desde cualquier IP
- **8069 (Odoo)**: ❌ BLOQUEADO externamente (solo via Nginx)

---

## 🎨 Convenciones de Código

### Terraform

**Archivos principales**:
- `main-simple.tf`: Recursos AWS (EC2, Security Group)
- `variables-simple.tf`: Variables de entrada
- `outputs-simple.tf`: Outputs (IP, instance ID)

**Nomenclatura**:
- Recursos: `snake_case` (ej: `aws_instance.odoo_server`)
- Variables: `snake_case` (ej: `postgres_password`)

### Shell Scripts

**Estilo**:
- `#!/bin/bash` al inicio
- `set -e` para salir en error
- Logs con echo descriptivo
- Secciones delimitadas con `===`

**Ejemplo**:
```bash
echo "=========================================="
echo "=== 1. INSTALANDO DEPENDENCIAS ==="
echo "=========================================="
```

### Docker Compose

**Nomenclatura de servicios**:
- `postgresOdoo16` (PostgreSQL)
- `odooApp` (Odoo 17)
- `nginx` (Nginx + certbot)
- `certbot` (Let's Encrypt)

**Volúmenes**: Bind mounts a EFS (no volúmenes nombrados)

---

## 📝 Documentación

### Estructura

Toda la documentación está en `docs/`:

1. **INDICE-DOCUMENTACION.md**: Punto de entrada, navegación
2. **README-COMPLETO.md**: Referencia técnica exhaustiva
3. **GUIA-RAPIDA.md**: Comandos del día a día
4. **GUIA-DESARROLLADORES.md**: Modificar el proyecto
5. **DECISIONES-ARQUITECTURA.md**: ADR (por qué se decidió X)

### Formato de Documentación

- **Markdown** estándar
- **Emojis** para secciones (📋, 🚀, ✅, ❌, ⚠️)
- **Bloques de código** con lenguaje específico
- **Tablas** para comparativas
- **Diagramas ASCII** para arquitectura
- **Links relativos** entre documentos

---

## 🔄 Decisiones Arquitectónicas Clave

### 1. ¿Por qué Terraform en lugar de scripts?

**Decisión**: Usar Terraform para IaC

**Razón**:
- Estado declarativo vs imperativo
- Idempotencia garantizada
- Gestión de dependencias automática
- Plan/preview antes de aplicar
- Reutilizable y reproducible

**Ver**: `docs/DECISIONES-ARQUITECTURA.md` → Decisión #1

### 2. ¿Por qué reutilizar EFS, VPC, Elastic IP?

**Decisión**: No crear estos recursos con Terraform

**Razón**:
- EFS contiene datos críticos (no destruir)
- Elastic IP es estable para DNS
- VPC ya configurada correctamente
- Evita cambios accidentales en producción

**Ver**: `docs/DECISIONES-ARQUITECTURA.md` → Decisión #2

### 3. ¿Por qué dividir user_data en dos scripts?

**Decisión**: `user_data_simple.sh` (6KB) + `setup_odoo_complete.sh` (13KB)

**Razón**:
- AWS limita user_data a 16KB
- Permite actualizar lógica sin recrear Terraform
- `setup_odoo_complete.sh` se descarga desde GitHub (siempre actualizado)

**Ver**: `docs/DECISIONES-ARQUITECTURA.md` → Decisión #3

### 4. ¿Por qué Docker Compose?

**Decisión**: Docker Compose para orquestación

**Razón**:
- Simple y suficiente para este caso
- Networking automático entre contenedores
- Health checks integrados
- Fácil de debuggear

**Alternativas descartadas**: ECS, Kubernetes (overkill)

**Ver**: `docs/DECISIONES-ARQUITECTURA.md` → Decisión #4

### 5. ¿Por qué montar EFS en `/efs`?

**Decisión**: Punto de montaje `/efs/HELIPISTAS-ODOO-17/`

**Razón**:
- Claridad (no confundir con `/mnt` o `/data`)
- Evita conflictos con otros servicios
- Estructura clara para múltiples proyectos

**Ver**: `docs/DECISIONES-ARQUITECTURA.md` → Decisión #5

### 6. ¿Por qué proxy_mode=True en Odoo?

**Decisión**: Odoo con `proxy_mode = True`

**Razón**:
- Nginx como proxy reverso
- Odoo no expuesto directamente
- Headers X-Forwarded-* correctos
- Mejora seguridad y performance

**Ver**: `docs/DECISIONES-ARQUITECTURA.md` → Decisión #8

### 7. ¿Por qué 2 workers de Odoo?

**Decisión**: `workers = 2` en odoo.conf

**Razón**:
- t3.medium tiene 2 vCPUs
- 1 worker por vCPU es óptimo
- workers=0 (desarrollo) vs workers=2 (producción)

**Ver**: `docs/DECISIONES-ARQUITECTURA.md` → Decisión #9

---

## 🚦 Estado del Proyecto

### ✅ Completado

- [x] Deployment On-Demand (producción)
- [x] Documentación completa (6 docs, ~5000 líneas)
- [x] Terraform funcional y validado
- [x] SSL automático con Let's Encrypt
- [x] Persistencia en EFS
- [x] Reorganización del repositorio

### 🚧 En Desarrollo

- [ ] Deployment con Spot Instances
- [ ] Manejo de interrupciones de Spot
- [ ] DNS automático para Spot

### 📝 Futuro

- [ ] CI/CD con GitHub Actions
- [ ] Monitoreo con CloudWatch
- [ ] Backup automático de PostgreSQL
- [ ] Multi-región (disaster recovery)

---

## 🔧 Modificaciones Comunes

### Cambiar versión de Odoo

**Archivo**: `deployments/on-demand/setup_odoo_complete.sh`

**Línea**: ~50 (en docker-compose.yml generado)

```bash
# Cambiar de:
image: odoo:17

# A:
image: odoo:18
```

### Cambiar tipo de instancia EC2

**Archivo**: `deployments/on-demand/terraform/variables-simple.tf`

```hcl
variable "instance_type" {
  default = "t3.medium"  # Cambiar a t3.large, t3.small, etc.
}
```

### Agregar módulo custom a Odoo

1. SSH a la instancia
2. Copiar módulo a `/efs/HELIPISTAS-ODOO-17/odoo/addons/`
3. Reiniciar Odoo: `docker-compose restart odoo`
4. Instalar módulo desde UI de Odoo

### Cambiar dominio

**Archivo**: `deployments/on-demand/terraform/terraform.tfvars`

```hcl
domain_name = "nuevo-dominio.com"
```

**Además**:
1. Actualizar DNS (Route 53 o similar)
2. `terraform apply`
3. Esperar propagación DNS (~5 min)

---

## 🐛 Troubleshooting Común

### Terraform falla con "Instance already exists"

**Causa**: Estado de Terraform desincronizado

**Solución**:
```bash
terraform destroy  # Elimina instancia
terraform apply    # Recrea limpia
```

### Odoo no arranca

**Diagnóstico**:
```bash
ssh -i /path/to/key.pem ec2-user@<IP>
docker-compose logs odoo
```

**Causas comunes**:
- PostgreSQL no listo (esperar 1-2 min)
- Error en contraseñas
- Falta espacio en disco

### SSL no funciona

**Diagnóstico**:
```bash
docker-compose logs certbot
docker-compose logs nginx
```

**Causas comunes**:
- DNS no apunta a IP correcta
- Firewall bloquea puerto 80
- Dominio no válido

### EFS no monta

**Diagnóstico**:
```bash
sudo tail -f /var/log/user-data.log
mount | grep efs
```

**Causas comunes**:
- Security Group no permite NFS
- EFS ID incorrecto
- Zona de disponibilidad diferente

---

## 🎯 Objetivos al Escribir Código

### Prioridades

1. **Seguridad**: Nunca exponer secrets, validar inputs
2. **Idempotencia**: Ejecutar scripts múltiples veces sin errores
3. **Logging**: Echo descriptivo en cada paso
4. **Reversibilidad**: Poder hacer rollback fácilmente
5. **Documentación**: Comentar decisiones no obvias

### Anti-Patterns a Evitar

❌ **NO hacer**:
- Hardcodear secrets en código
- Eliminar recursos AWS existentes (EFS, Elastic IP)
- Modificar `setup_odoo_complete.sh` sin actualizar en raíz Y en deployments/on-demand/
- Crear volúmenes Docker nombrados (usar bind mounts a EFS)
- Exponer Odoo directamente (siempre via Nginx)

✅ **SÍ hacer**:
- Usar variables de Terraform para configuración
- Verificar existencia de recursos antes de crearlos
- Logs descriptivos con timestamps
- Health checks en Docker Compose
- Mantener sincronizados scripts en raíz y deployments/

---

## 📞 Referencias Rápidas

### Comandos Terraform

```bash
# Inicializar
terraform init

# Validar sintaxis
terraform validate

# Ver plan
terraform plan

# Aplicar cambios
terraform apply

# Destruir todo
terraform destroy

# Ver outputs
terraform output
```

### Comandos Docker Compose

```bash
# En la instancia EC2, en /efs/HELIPISTAS-ODOO-17/

# Ver logs
docker-compose logs -f

# Ver estado
docker-compose ps

# Reiniciar
docker-compose restart

# Reiniciar un servicio
docker-compose restart odoo

# Detener todo
docker-compose down

# Iniciar todo
docker-compose up -d
```

### SSH a la Instancia

```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
```

### URLs Importantes

- **Odoo**: https://erp17.helipistas.com
- **GitHub raw setup script**: https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/setup_odoo_complete.sh
- **Repositorio**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts

---

## 🎓 Para Nuevos Desarrolladores

### Onboarding (2-3 horas)

1. **Leer** `README.md` (10 min)
2. **Leer** `docs/RESUMEN-EJECUTIVO.md` (15 min)
3. **Leer** `docs/GUIA-DESARROLLADORES.md` (1 hora)
4. **Revisar** `deployments/on-demand/terraform/main-simple.tf` (30 min)
5. **Ejecutar** deployment en cuenta AWS de prueba (30 min)

### Primeras Tareas Sugeridas

1. Hacer cambio cosmético en README y PR
2. Agregar variable a Terraform
3. Modificar configuración de Nginx
4. Probar destruir/recrear deployment

---

## 🔍 Testing

### Validar Terraform

```bash
cd deployments/on-demand/terraform
terraform init
terraform validate
terraform plan  # No aplicar, solo validar
```

### Validar Scripts

```bash
# Sintaxis
bash -n setup_odoo_complete.sh

# Ejecutar en dry-run (si se implementa)
# ./setup_odoo_complete.sh --dry-run
```

### Validar Docker Compose

```bash
# En EC2
docker-compose config  # Valida sintaxis
```

---

## 📊 Métricas de Éxito

### Deployment

- ✅ Tiempo de deployment: < 15 min
- ✅ Éxito de SSL: 100%
- ✅ Uptime Odoo: > 99% (on-demand)
- ✅ Uptime Odoo: > 95% (spot)

### Costos

- ✅ On-Demand: < $50/mes
- ✅ Spot: < $15/mes
- ✅ EFS: Variable según uso

---

## 🌟 Filosofía del Proyecto

### Principios

1. **Automatización completa**: Un comando debe desplegar todo
2. **Idempotencia**: Ejecutar múltiples veces sin efectos secundarios
3. **Documentación exhaustiva**: Código auto-documentado + docs/
4. **Reversibilidad**: Fácil rollback y disaster recovery
5. **Separación de concerns**: Terraform (infra) vs Scripts (config)

### Valores

- **Claridad** sobre brevedad
- **Seguridad** sobre conveniencia
- **Reproducibilidad** sobre optimización prematura
- **Documentación** como código de primera clase

---

## 📌 TODOs y Mejoras Futuras

### Alta Prioridad

- [ ] Implementar deployment con Spot Instances
- [ ] Agregar manejo de interrupciones de Spot
- [ ] Implementar DNS automático para Spot

### Media Prioridad

- [ ] CI/CD con GitHub Actions
- [ ] Monitoreo con CloudWatch/Prometheus
- [ ] Backup automático de PostgreSQL
- [ ] Alertas en Slack/Email

### Baja Prioridad

- [ ] Multi-región para disaster recovery
- [ ] Auto-scaling basado en métricas
- [ ] Migración a Kubernetes (si escala)

---

## 🤝 Contribuir al Proyecto

### Workflow

1. Fork del repositorio
2. Crear branch: `git checkout -b feature/amazing-feature`
3. Hacer cambios
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Crear Pull Request

### Checklist de PR

- [ ] Tests pasan (terraform validate)
- [ ] Documentación actualizada
- [ ] CHANGELOG.md actualizado (si aplica)
- [ ] Sin secrets en código
- [ ] Mensaje de commit descriptivo

---

## 📄 Licencia

MIT - Ver `LICENSE` para detalles

---

**Última actualización**: 19 Noviembre 2025  
**Versión**: 2.0 (después de reorganización)  
**Mantenedor**: @leulit
