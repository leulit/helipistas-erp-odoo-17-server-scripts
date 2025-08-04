SERVER-SCRIPTS/
├── 🚀 deploy.sh              # Script principal de despliegue automático
├── 🔧 manage.sh               # Script de gestión y mantenimiento
├── 📖 README.md               # Documentación completa
├── ⚡ QUICKSTART.md           # Guía de inicio rápido
├── 📄 LICENSE                 # Licencia MIT
├── 🙈 .gitignore             # Archivos a ignorar en git
├── terraform/                 # 🏗️ Infraestructura como código
│   ├── main.tf               # Recursos AWS (VPC, EC2, Security Groups)
│   ├── variables.tf          # Variables configurables
│   ├── outputs.tf            # Outputs del despliegue
│   ├── user_data.sh          # Script de auto-configuración EC2
│   └── terraform.tfvars.example # Plantilla de configuración
├── docker/                    # 🐳 Configuración de contenedores
│   ├── docker-compose.yml    # Servicios: Odoo, PostgreSQL, Nginx
│   ├── .env.example          # Variables de entorno
│   ├── config/odoo.conf      # Configuración optimizada de Odoo
│   └── nginx/                # Configuración de proxy reverso
│       ├── nginx.conf        # Configuración principal
│       ├── default.conf      # Virtual host HTTP
│       └── ssl.conf.example  # Virtual host HTTPS
└── scripts/                   # 🛠️ Scripts de mantenimiento
    ├── backup.sh             # Backup automático con S3
    ├── restore.sh            # Restauración de backups
    └── monitor.sh            # Monitoreo y alertas


🚀 Características Principales
✅ Infraestructura AWS Optimizada:

EC2 Spot Instance (60-90% más barato)
VPC con security groups seguros
Elastic IP estática (crear nueva o usar existente)
EFS opcional para persistencia de datos
Auto-configuración con user data
Terraform para infraestructura reproducible

**✅ Arquitectura Docker:**
- Nginx como proxy reverso con caché
- Odoo 17 optimizado para producción
- PostgreSQL 15 con configuración óptima
- Health checks y auto-restart
- Actualizaciones manuales controladas (sin auto-updates)

✅ Seguridad:

SSL/HTTPS con Let's Encrypt automático
Firewall configurado (solo puertos necesarios)
SSH con claves, no contraseñas
Acceso abierto desde cualquier IP
Contraseñas seguras generadas automáticamente

✅ Backup y Monitoreo:

Backups automáticos diarios
Subida opcional a S3
Monitoreo de recursos y servicios
Alertas por webhook (Slack/Discord)
Health checks integrados

✅ Gestión Simplificada:

Despliegue con un comando: deploy.sh
Gestión fácil: .[manage.sh](http://_vscodecontentref_/1) status|logs|backup|restart
Scripts de troubleshooting incluidos
Documentación completa paso a paso
💰 Costos Estimados
Desarrollo: ~$15-20/mes
Producción: ~$25-40/mes
Ahorro con Spot: 60-90% vs instancias On-Demand

## 🔧 **Configuración de Recursos Existentes**

### **📍 Usar Elastic IP Existente**
Si ya tienes una Elastic IP que quieres reutilizar:

```bash
# En terraform.tfvars
existing_elastic_ip_id = "eip-1234567890abcdef0"
```

**Beneficios:**
- ✅ Conservar la misma IP pública
- ✅ No perder configuraciones DNS
- ✅ Evitar cambios en firewalls/whitelists
- ✅ Continuidad para certificados SSL

### **💾 Usar EFS Existente para Persistencia**
Si quieres datos persistentes que sobrevivan a la recreación de instancias:

```bash
# En terraform.tfvars
existing_efs_id = "fs-1234567890abcdef0"
efs_mount_point = "/opt/odoo/data"
```

**Qué se monta en EFS:**
- 📁 Addons personalizados de Odoo
- 📁 Archivos de configuración
- 📁 Logs persistentes
- 📁 Archivos subidos por usuarios
- 📁 Backups automáticos

**Ventajas de EFS:**
- ✅ Datos sobreviven a terminación de instancia
- ✅ Backups automáticos de AWS
- ✅ Escalabilidad automática
- ✅ Acceso desde múltiples instancias
- ✅ Cifrado en reposo y en tránsito

### **🔍 Encontrar IDs de Recursos Existentes**

```bash
# Listar Elastic IPs disponibles
aws ec2 describe-addresses --region us-east-1

# Listar sistemas de archivos EFS
aws efs describe-file-systems --region us-east-1

# Ver detalles de un EFS específico
aws efs describe-file-systems --file-system-id fs-1234567890abcdef0
```

🚀 Para Empezar
Configurar AWS CLI y Terraform
Copiar y editar terraform.tfvars.example
Ejecutar deploy.sh
¡Listo! Tu Odoo estará funcionando en minutos
📚 Documentación
README.md: Documentación completa con todos los detalles
QUICKSTART.md: Guía de inicio en 5 minutos
Ejemplos de configuración incluidos
Solución de problemas comunes
Mejores prácticas de seguridad
🛠️ Scripts Disponibles

**🎯 El proyecto está listo para usar en producción y incluye todo lo necesario para gestionar un servidor Odoo robusto, seguro y económico en AWS.**

## 🧹 **Limpieza y Control de Costos**

### **⚠️ CRÍTICO para Pruebas y Desarrollo**

Durante las pruebas es **FUNDAMENTAL** limpiar todos los recursos para evitar costos inesperados:

```bash
# 1. Ver qué recursos están activos (sin eliminar)
./deploy.sh --scan
./manage.sh scan

# 2. Ver costos actuales
./manage.sh costs

# 3. Limpieza completa - ELIGE UNA OPCIÓN:

# Opción A: Terraform (RECOMENDADO)
./deploy.sh --destroy

# Opción B: Script de limpieza manual (si Terraform falla)
./cleanup.sh --force

# Opción C: Desde manage.sh
./manage.sh cleanup --force

# 4. VERIFICAR limpieza (IMPORTANTE)
./deploy.sh --scan    # Debe mostrar "No se encontraron recursos"
```

### **💰 Recursos que SIEMPRE Cobran**

```bash
# Estos recursos cobran aunque no los uses:
Elastic IP no asociada    = $3.60/mes
Volúmenes EBS huérfanos  = $0.10/GB/mes  
NAT Gateway huérfano     = $45/mes 🔥
Load Balancer huérfano   = $18/mes

# ⚠️ Un simple olvido puede costar $50-100/mes extra
```

### **🛡️ Triple Protección Anti-Huérfanos**

1. **🏗️ Terraform State**: Rastrea automáticamente todos los recursos
2. **🏷️ Tags Inteligentes**: Todos los recursos marcados con `Project=helipistas-odoo`
3. **🔍 Script de Limpieza**: Busca y elimina recursos por tags

### **📊 Monitoreo de Costos en Tiempo Real**

```bash
# Ver estimación de costos actuales
./manage.sh costs

# Salida ejemplo:
# 💰 Costos estimados de recursos activos:
#   - Por hora: $0.0416
#   - Por día: $1.00
#   - Por mes: $30.00
```

### **🚨 Workflow Seguro para Pruebas**

```bash
# ANTES de crear recursos
./deploy.sh --scan              # ¿Hay algo ya creado?

# CREAR recursos para pruebas
./deploy.sh                     # Despliegue completo

# DURANTE las pruebas
./manage.sh costs               # Monitorear costos
./manage.sh status              # Verificar funcionamiento

# DESPUÉS de pruebas (CRÍTICO)
./deploy.sh --destroy           # Eliminar TODO
./deploy.sh --scan              # Verificar limpieza completa
```

---

## 🔄 **Actualizaciones Manuales y Controladas**

### **🛡️ Filosofía: Actualizaciones Seguras**

Este proyecto **NO incluye actualizaciones automáticas** por seguridad. Todas las actualizaciones se realizan manualmente y de forma controlada para evitar:
- ❌ Ruptura de compatibilidad sin aviso
- ❌ Downtime inesperado en producción  
- ❌ Pérdida de datos por actualizaciones defectuosas
- ❌ Cambios de configuración no deseados

### **📋 Proceso de Actualización Recomendado**

#### **1. 🔍 Verificar Versiones Actuales**
```bash
# Ver versiones de contenedores actualmente en uso
./manage.sh remote 'docker images | grep -E "(odoo|postgres|nginx)"'

# Ver estado actual del sistema
./manage.sh status
```

#### **2. 📥 Backup Obligatorio Antes de Actualizar**
```bash
# SIEMPRE crear backup antes de actualizar
./manage.sh backup

# Verificar que el backup se creó correctamente
./manage.sh download-backup <archivo_backup>
```

#### **3. 🧪 Actualización en Entorno de Prueba**
```bash
# 1. Crear entorno de prueba temporal
./deploy.sh --plan              # Ver recursos que se crearán
./deploy.sh                     # Crear entorno de prueba

# 2. Actualizar contenedores en prueba
./manage.sh update              # Actualizar a últimas versiones

# 3. Probar funcionalidad crítica
./manage.sh logs                # Verificar logs
./manage.sh status              # Verificar servicios
# ... probar aplicación manualmente ...

# 4. Si todo funciona, documentar versiones
./manage.sh remote 'docker images | grep -E "(odoo|postgres|nginx)"'

# 5. Eliminar entorno de prueba
./deploy.sh --destroy
```

#### **4. 🚀 Actualización en Producción**
```bash
# 1. Notificar a usuarios del mantenimiento
# 2. Crear backup de producción
./manage.sh backup

# 3. Actualizar contenedores (modo conservador)
./manage.sh remote 'cd /opt/odoo && docker-compose pull'
./manage.sh remote 'cd /opt/odoo && docker-compose up -d'

# 4. Verificar que todo funciona
./manage.sh status
./manage.sh logs

# 5. Probar funcionalidad crítica manualmente
```

### **🔧 Comandos de Actualización Manual**

#### **Actualizar Solo Odoo**
```bash
# Actualizar solo el contenedor de Odoo
./manage.sh remote 'cd /opt/odoo && docker-compose pull odoo'
./manage.sh remote 'cd /opt/odoo && docker-compose up -d odoo'
```

#### **Actualizar Solo PostgreSQL**
```bash
# ⚠️ CUIDADO: Backup obligatorio antes de actualizar BD
./manage.sh backup
./manage.sh remote 'cd /opt/odoo && docker-compose pull postgresql'
./manage.sh remote 'cd /opt/odoo && docker-compose up -d postgresql'
```

#### **Actualizar Solo Nginx**
```bash
# Actualizar solo el proxy reverso
./manage.sh remote 'cd /opt/odoo && docker-compose pull nginx'
./manage.sh remote 'cd /opt/odoo && docker-compose up -d nginx'
```

#### **Actualizar Todo (Conservador)**
```bash
# Actualizar todos los contenedores de forma segura
./manage.sh update              # Usa el script integrado
```

### **🧪 Estrategia de Actualización por Entornos**

#### **🔬 Desarrollo/Testing**
```bash
# Actualizaciones frecuentes para probar
./manage.sh update              # Actualizar a latest
./manage.sh logs                # Verificar funcionamiento
```

#### **🏭 Producción**
```bash
# Actualizaciones conservadoras y programadas
# 1. Planificar ventana de mantenimiento
# 2. Backup completo
# 3. Actualización step-by-step
# 4. Verificación exhaustiva
```

### **📊 Monitoreo Post-Actualización**

```bash
# Verificar salud del sistema después de actualizar
./manage.sh status              # Estado general
./manage.sh monitor             # Recursos en tiempo real
./manage.sh logs odoo           # Logs específicos de Odoo

# Verificar que no hay errores
./manage.sh remote 'docker-compose -f /opt/odoo/docker-compose.yml logs --since=10m | grep -i error'
```

### **🚨 Plan de Rollback**

Si algo falla después de una actualización:

```bash
# 1. Parar servicios actualizados
./manage.sh remote 'cd /opt/odoo && docker-compose down'

# 2. Restaurar desde backup
./manage.sh remote 'sudo /opt/odoo/restore.sh <backup_file>'

# 3. Verificar funcionamiento
./manage.sh status

# 4. Investigar causa del fallo
./manage.sh logs
```

### **💡 Mejores Prácticas de Actualización**

✅ **SÍ hacer:**
- Backup antes de cualquier actualización
- Probar en entorno separado primero
- Actualizar en ventanas de mantenimiento programadas
- Leer changelogs antes de actualizar
- Verificar compatibilidad entre versiones
- Mantener documentación de versiones

❌ **NO hacer:**
- Actualizar directamente en producción
- Actualizar sin backup
- Actualizar múltiples componentes simultáneamente
- Ignorar warnings en logs
- Actualizar sin plan de rollback
```