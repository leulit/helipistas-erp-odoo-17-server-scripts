# 🏛️ Decisiones de Arquitectura - Helipistas Odoo 17

## 📋 Documento de Registro de Decisiones de Arquitectura (ADR)

Este documento explica **por qué** se tomaron las decisiones técnicas clave en el proyecto.

---

## 1. Usar Terraform en lugar de scripts manuales

### Contexto

Necesitábamos una forma de crear y gestionar infraestructura AWS de manera reproducible.

### Decisión

Usar **Terraform** como herramienta de Infrastructure as Code (IaC).

### Razones

✅ **Reproducibilidad**: Mismo código produce misma infraestructura
✅ **Versionado**: Infraestructura en Git, historial de cambios
✅ **Declarativo**: Defines el estado deseado, no los pasos
✅ **Plan before apply**: Ver cambios antes de aplicarlos
✅ **Community**: Gran comunidad y documentación

### Alternativas Consideradas

- **CloudFormation**: Más verboso, específico de AWS
- **Ansible**: Mejor para configuración que para infraestructura
- **Scripts Bash con AWS CLI**: No declarativo, difícil de mantener

### Consecuencias

- ✅ Infraestructura fácil de recrear
- ✅ Cambios rastreables en Git
- ⚠️ Curva de aprendizaje para Terraform
- ⚠️ Estado de Terraform (terraform.tfstate) debe ser gestionado

---

## 2. Reutilizar recursos AWS existentes (EFS, VPC, Elastic IP)

### Contexto

Ya existían recursos AWS en la cuenta que queríamos mantener.

### Decisión

Usar **data sources** de Terraform para referenciar recursos existentes en lugar de crearlos.

### Razones

✅ **Persistencia de datos**: EFS contiene datos que no deben perderse
✅ **IP estática**: Elastic IP ya configurada en DNS
✅ **Costos**: Evitar duplicar recursos
✅ **VPC existente**: Ya configurada correctamente

### Recursos Reutilizados

```hcl
data "aws_vpc" "main" {
  id = "vpc-92d074f6"  # Existente
}

data "aws_subnet" "public" {
  subnet_id = "subnet-c362e2a7"  # Existente
}

# Variables para recursos externos
variable "existing_efs_id" {
  default = "fs-ec7152d9"
}

variable "existing_elastic_ip_id" {
  default = "eipalloc-0184418cc26d4e66f"
}
```

### Consecuencias

- ✅ Datos persisten entre deployments
- ✅ IP no cambia (DNS consistente)
- ⚠️ Dependencia de recursos fuera de Terraform
- ⚠️ Terraform destroy no elimina estos recursos

---

## 3. Dividir user_data en dos scripts (simple + completo)

### Contexto

AWS limita user_data a 16KB. Nuestro script completo excedía este límite.

### Decisión

Dividir en:
1. **user_data_simple.sh**: Setup básico, descarga script completo
2. **setup_odoo_complete.sh**: Configuración detallada (en GitHub)

### Razones

✅ **Límite AWS**: 16KB user_data máximo
✅ **Actualización fácil**: Cambiar `setup_odoo_complete.sh` en GitHub sin tocar Terraform
✅ **Separación de responsabilidades**: Sistema vs. Aplicación
✅ **Debugging**: Logs separados facilitan troubleshooting

### Flujo

```
user_data_simple.sh (6KB)
  ├── Instala dependencias
  ├── Monta EFS
  ├── Crea directorios
  └── Descarga setup_odoo_complete.sh desde GitHub
      └── setup_odoo_complete.sh (24KB)
          ├── Crea docker-compose.yml
          ├── Configura Odoo
          ├── Configura Nginx
          └── Obtiene SSL
```

### Consecuencias

- ✅ No limitados por 16KB de user_data
- ✅ Actualizar configuración sin cambiar Terraform
- ✅ Script completo versionado en GitHub
- ⚠️ Requiere acceso a Internet para descargar script
- ⚠️ Dependencia de GitHub (rama main)

---

## 4. Usar Docker Compose en lugar de servicios nativos

### Contexto

Necesitábamos gestionar PostgreSQL, Odoo, Nginx y Certbot de forma coordinada.

### Decisión

Usar **Docker Compose** para orquestar todos los servicios.

### Razones

✅ **Aislamiento**: Cada servicio en su contenedor
✅ **Portabilidad**: Mismo stack en dev, staging, prod
✅ **Versiones exactas**: Control preciso de versiones
✅ **Facilidad de gestión**: `docker-compose restart/logs/ps`
✅ **Networking**: Red interna automática entre contenedores
✅ **Volúmenes**: Datos persistentes en EFS

### Arquitectura de Servicios

```yaml
services:
  postgresOdoo16:      # Base de datos
    image: postgres:15
    volumes: /efs/.../postgres

  helipistas_odoo:     # Aplicación ERP
    image: odoo:17
    depends_on: postgresOdoo16
    volumes: /efs/.../odoo

  nginx:               # Proxy reverso + SSL
    image: nginx:latest
    depends_on: helipistas_odoo
    volumes: /efs/.../nginx

  certbot:             # Gestión SSL
    image: certbot/certbot
    volumes: /efs/.../certbot
```

### Alternativas Consideradas

- **Kubernetes**: Overkill para un solo servidor
- **Servicios systemd**: Menos portables, más complejidad
- **Docker sin Compose**: Gestión manual de red y dependencias

### Consecuencias

- ✅ Fácil de gestionar con un solo archivo (docker-compose.yml)
- ✅ Servicios se reinician automáticamente (`restart: unless-stopped`)
- ✅ Red interna segura entre contenedores
- ⚠️ Requiere Docker instalado en host
- ⚠️ Logs dentro de contenedores (usar `docker logs`)

---

## 5. Montar EFS en /efs en lugar de directorios individuales

### Contexto

Necesitábamos persistencia de datos que sobreviva a recreación de instancias.

### Decisión

Montar **todo EFS en /efs** y organizar datos del proyecto en subdirectorios.

### Razones

✅ **Single mount point**: Un solo mount de NFS
✅ **Organización clara**: `/efs/HELIPISTAS-ODOO-17/`
✅ **Compartible**: Múltiples instancias pueden montar el mismo EFS
✅ **Backup fácil**: Todo en un lugar
✅ **Permisos**: Control granular por subdirectorio

### Estructura de Datos

```
/efs/HELIPISTAS-ODOO-17/
├── postgres/        (chown 999:999)  # Usuario postgres en contenedor
├── odoo/            (chown 101:101)  # Usuario odoo en contenedor
├── nginx/           (chown 101:101)
└── certbot/         (chown 101:101)
```

### Comando de Montaje

```bash
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport \
  fs-ec7152d9.efs.eu-west-1.amazonaws.com:/ /efs
```

### Consecuencias

- ✅ Datos sobreviven a terminación de EC2
- ✅ Alta disponibilidad (EFS multi-AZ)
- ✅ Escalabilidad automática de almacenamiento
- ⚠️ Latencia de red (NFS)
- ⚠️ Costo por GB almacenado

---

## 6. SSL automático con Let's Encrypt en lugar de certificado manual

### Contexto

Necesitábamos HTTPS con certificado válido y renovación automática.

### Decisión

Usar **Let's Encrypt** con **Certbot** para obtener y renovar certificados automáticamente.

### Razones

✅ **Gratis**: Let's Encrypt no cobra
✅ **Automático**: Certbot maneja obtención y renovación
✅ **Válido**: Reconocido por todos los navegadores
✅ **Renovación automática**: Cada 12 horas verifica si debe renovar
✅ **Wildcard opcional**: Soporte para *.dominio.com

### Flujo de Obtención

```
1. Nginx escucha en puerto 80 (HTTP)
2. Certbot solicita certificado via ACME challenge
3. Let's Encrypt valida dominio via HTTP
   └─► GET http://erp17.helipistas.com/.well-known/acme-challenge/[token]
4. Let's Encrypt emite certificado (válido 90 días)
5. Certbot guarda certificado en /efs/.../certbot/conf
6. Nginx se reconfigura para HTTPS (puerto 443)
7. Certbot contenedor queda corriendo para renovación
```

### Renovación Automática

```yaml
certbot:
  image: certbot/certbot
  entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
```

### Alternativas Consideradas

- **Certificado auto-firmado**: No válido para navegadores
- **Certificado comercial**: Costo anual, renovación manual
- **AWS Certificate Manager**: Solo para Load Balancer/CloudFront

### Consecuencias

- ✅ HTTPS funcionando automáticamente
- ✅ Sin costos de certificado
- ✅ Renovación sin intervención manual
- ⚠️ Requiere dominio público válido
- ⚠️ Límites de rate de Let's Encrypt (20 certs/semana)

---

## 7. Nginx como proxy reverso en lugar de exponer Odoo directamente

### Contexto

Odoo corre en puerto 8069 sin HTTPS nativo.

### Decisión

Usar **Nginx como proxy reverso** delante de Odoo.

### Razones

✅ **SSL Termination**: Nginx maneja HTTPS, Odoo solo HTTP
✅ **Performance**: Nginx sirve archivos estáticos mejor que Odoo
✅ **Seguridad**: Capa adicional de protección
✅ **Caching**: Nginx puede cachear respuestas
✅ **Load Balancing**: Fácil agregar más instancias de Odoo

### Arquitectura

```
Internet
   ↓
Nginx:443 (HTTPS)
   ↓
Nginx → Odoo:8069 (HTTP interno)
   ↓
PostgreSQL:5432
```

### Configuración Clave

```nginx
location / {
    proxy_pass http://helipistas_odoo:8069;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;  # Importante para Odoo
}
```

### Consecuencias

- ✅ HTTPS terminado en Nginx
- ✅ Odoo no necesita configuración SSL
- ✅ Headers correctos para proxy mode de Odoo
- ⚠️ Capa adicional de complejidad
- ⚠️ Logs en dos lugares (Nginx + Odoo)

---

## 8. Configurar Odoo con proxy_mode = True

### Contexto

Odoo detrás de Nginx necesita saber que está detrás de un proxy.

### Decisión

Habilitar **proxy_mode** en odoo.conf.

### Razones

✅ **Headers correctos**: Odoo usa X-Forwarded-* headers
✅ **URLs correctas**: Odoo genera URLs con https:// correcto
✅ **Seguridad**: Previene bypassing del proxy
✅ **Redirecciones**: Redirecciones HTTPS funcionan correctamente

### Configuración

```ini
[options]
proxy_mode = True
```

### Qué hace proxy_mode

- Lee header `X-Forwarded-Proto` para saber si es HTTP o HTTPS
- Lee header `X-Forwarded-For` para IP real del cliente
- Genera URLs con scheme correcto (https://)
- Previene acceso directo al puerto 8069 desde fuera

### Consecuencias

- ✅ Odoo funciona correctamente detrás de proxy
- ✅ URLs generadas son HTTPS
- ✅ Logs muestran IP real del cliente
- ⚠️ Odoo confía en headers (Nginx debe validarlos)

---

## 9. 2 workers de Odoo en lugar de modo single-thread

### Contexto

Odoo por defecto corre en modo single-thread, limitando concurrencia.

### Decisión

Configurar **2 workers** para la instancia t3.medium.

### Razones

✅ **Concurrencia**: Múltiples requests simultáneos
✅ **Performance**: Mejor uso de 2 vCPUs de t3.medium
✅ **Responsiveness**: Sistema más ágil con varios usuarios

### Configuración

```ini
[options]
workers = 2
max_cron_threads = 1
limit_memory_hard = 1677721600  # 1.6 GB
limit_memory_soft = 1342177280  # 1.25 GB
```

### Cálculo de Workers

```
Regla general: workers = (cores * 2) + 1
Para t3.medium (2 vCPU):
  workers = (2 * 2) + 1 = 5

Pero usamos 2 workers porque:
- RAM limitada (4 GB total)
- 1.6 GB por worker máximo
- 2 workers = 3.2 GB máximo
- Deja RAM para PostgreSQL y sistema
```

### Consecuencias

- ✅ Mejor concurrencia que modo single-thread
- ✅ Uso eficiente de CPU
- ⚠️ Más consumo de RAM
- ⚠️ Workers adicionales requieren más RAM

---

## 10. Usar EC2 regular en lugar de Spot Instance

### Contexto

Spot instances son más baratas pero pueden ser terminadas por AWS.

### Decisión

Usar **instancia EC2 On-Demand** (no Spot).

### Razones

✅ **Disponibilidad garantizada**: No se termina inesperadamente
✅ **Datos en EFS**: Si se termina EC2, solo recrear instancia
✅ **Simplicidad**: No manejar interrupciones de Spot
✅ **SLA**: Mejor SLA para producción

### Costo Comparativo

| Tipo | Costo/hora | Costo/mes | Ahorro |
|------|-----------|-----------|--------|
| On-Demand | $0.0416 | $30.00 | Baseline |
| Spot (promedio) | $0.0125 | $9.00 | 70% |

### Consideración Futura

Si se necesita reducir costos:
- Usar Spot para dev/staging
- Mantener On-Demand para producción
- Implementar manejo de interrupciones de Spot

### Consecuencias

- ✅ Alta disponibilidad
- ✅ Sin interrupciones inesperadas
- ⚠️ Costo mayor que Spot
- ⚠️ Sigue siendo económico (~$30/mes)

---

## 11. Terraform fuerza recreación de instancia en cada apply

### Contexto

Queríamos que `terraform apply` siempre cree infraestructura fresca.

### Decisión

Usar **timestamp en user_data** para forzar recreación.

### Razones

✅ **Infraestructura fresca**: Cada apply crea nueva instancia
✅ **Testing**: Valida que deployment automático funciona
✅ **No state drift**: Configuración siempre desde cero
✅ **EFS preserva datos**: Recrear EC2 es seguro

### Implementación

```hcl
user_data_base64 = base64encode("${templatefile("${path.module}/user_data_simple.sh", {
  POSTGRES_PASSWORD    = var.postgres_password
  ODOO_MASTER_PASSWORD = var.odoo_master_password
  EFS_ID               = var.existing_efs_id
  ELASTIC_IP_ID        = var.existing_elastic_ip_id
  DOMAIN_NAME          = var.domain_name
})}-${timestamp()}")  # ← timestamp() cambia en cada apply
```

### Consecuencias

- ✅ `terraform apply` siempre crea instancia nueva
- ✅ Valida que deployment automático funciona
- ✅ Datos persisten en EFS
- ⚠️ Downtime de ~10 minutos en cada apply
- ⚠️ IP Elastic se reasigna (puede tomar 1-2 min)

---

## 12. Flags --force-renewal y --non-interactive en certbot

### Contexto

Certbot pedía confirmación interactiva si certificado ya existía.

### Decisión

Usar **--force-renewal --non-interactive** en comando certbot.

### Razones

✅ **No interactivo**: No pide confirmación del usuario
✅ **Fuerza renovación**: Renueva aunque certificado no esté cerca de expirar
✅ **Deployment automático**: Script no se queda colgado

### Comando

```bash
docker run --rm certbot/certbot \
  certonly --webroot --webroot-path=/var/www/certbot \
  --email admin@helipistas.com \
  --agree-tos \
  --no-eff-email \
  --force-renewal \     # ← Fuerza renovación
  --non-interactive \   # ← No pide confirmación
  -d erp17.helipistas.com
```

### Consecuencias

- ✅ Deployment completamente automático
- ✅ No se queda esperando input
- ⚠️ Puede llegar a rate limit de Let's Encrypt si se abusa
- ⚠️ Renueva certificado incluso si tiene 89 días válidos

---

## 📊 Resumen de Trade-offs

| Decisión | Ventaja Principal | Desventaja Principal |
|----------|-------------------|---------------------|
| Terraform | Reproducibilidad | Curva de aprendizaje |
| Reutilizar EFS/VPC | Persistencia de datos | Dependencia externa |
| Scripts divididos | Sin límite 16KB user_data | Dependencia de GitHub |
| Docker Compose | Aislamiento y portabilidad | Complejidad adicional |
| EFS montado en /efs | Organización clara | Latencia de red |
| Let's Encrypt | Gratis y automático | Requiere dominio público |
| Nginx proxy | SSL termination | Capa adicional |
| proxy_mode=True | URLs correctas | Confía en headers |
| 2 workers | Mejor concurrencia | Más RAM |
| EC2 On-Demand | Alta disponibilidad | Costo vs Spot |
| Timestamp en user_data | Infraestructura fresca | Downtime en cada apply |
| certbot flags | Totalmente automático | Puede abusar rate limit |

---

## 🔮 Decisiones Futuras a Considerar

### 1. Remote State de Terraform

**Problema actual**: `terraform.tfstate` está en local

**Solución propuesta**: S3 + DynamoDB para remote state

**Beneficios**:
- Colaboración en equipo
- State locking
- Backup automático

### 2. CI/CD Pipeline

**Problema actual**: Deployment manual

**Solución propuesta**: GitHub Actions para terraform apply automático

**Beneficios**:
- Deployment al hacer push a main
- Testing automático
- Rollback fácil

### 3. Multi-ambiente

**Problema actual**: Un solo ambiente (producción)

**Solución propuesta**: Terraform workspaces o directorios separados

**Beneficios**:
- Dev, Staging, Production separados
- Testing seguro
- Menor riesgo

### 4. Monitoring y Alertas

**Problema actual**: No hay monitoreo activo

**Solución propuesta**: CloudWatch + SNS para alertas

**Beneficios**:
- Detectar problemas temprano
- Métricas de uso
- Alertas por email/Slack

### 5. Backup Automático a S3

**Problema actual**: Backups manuales

**Solución propuesta**: Cron job + AWS CLI para subir backups a S3

**Beneficios**:
- Redundancia fuera de EFS
- Backups programados
- Retención configurable

---

**Este documento explica el razonamiento detrás de cada decisión técnica importante, facilitando futuras modificaciones informadas del proyecto.** 🏛️
