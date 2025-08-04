# Estructura del Proyecto HLP-ERP-ODOO-17

## 📂 Organización de Directorios

Todo el proyecto se organiza bajo `/efs/HLP-ERP-ODOO-17/` (o localmente si no usas EFS):

```
/efs/HLP-ERP-ODOO-17/
├── POSTGRESQL/                 # Todo lo relacionado con PostgreSQL
│   ├── data/                  # Datos de la base de datos
│   ├── backups/               # Backups automáticos (.sql.gz)
│   ├── init/                  # Scripts de inicialización
│   └── logs/                  # Logs de PostgreSQL
├── ODOO/                      # Todo lo relacionado con Odoo
│   ├── addons/                # Módulos personalizados
│   ├── data/                  # Datos de aplicación Odoo
│   ├── config/                # Configuración (odoo.conf)
│   ├── filestore/             # Archivos subidos por usuarios
│   └── logs/                  # Logs de Odoo
└── NGINX/                     # Todo lo relacionado con Nginx
    ├── conf/                  # Configuración de Nginx
    ├── ssl/                   # Certificados SSL/TLS
    ├── logs/                  # Logs de acceso y errores
    └── cache/                 # Cache de contenido
```

## 🐳 Mapeo de Volúmenes Docker

### PostgreSQL Container
```yaml
volumes:
  - /efs/HLP-ERP-ODOO-17/POSTGRESQL/data:/var/lib/postgresql/data/pgdata
  - /efs/HLP-ERP-ODOO-17/POSTGRESQL/backups:/backup
  - /efs/HLP-ERP-ODOO-17/POSTGRESQL/init:/docker-entrypoint-initdb.d
  - /efs/HLP-ERP-ODOO-17/POSTGRESQL/logs:/var/log/postgresql
```

### Odoo Container
```yaml
volumes:
  - /efs/HLP-ERP-ODOO-17/ODOO/addons:/mnt/extra-addons
  - /efs/HLP-ERP-ODOO-17/ODOO/config:/etc/odoo
  - /efs/HLP-ERP-ODOO-17/ODOO/data:/var/lib/odoo
  - /efs/HLP-ERP-ODOO-17/ODOO/filestore:/var/lib/odoo/filestore
  - /efs/HLP-ERP-ODOO-17/ODOO/logs:/var/log/odoo
```

### Nginx Container
```yaml
volumes:
  - /efs/HLP-ERP-ODOO-17/NGINX/conf/nginx.conf:/etc/nginx/nginx.conf:ro
  - /efs/HLP-ERP-ODOO-17/NGINX/conf/default.conf:/etc/nginx/conf.d/default.conf:ro
  - /efs/HLP-ERP-ODOO-17/NGINX/ssl:/etc/nginx/ssl:ro
  - /efs/HLP-ERP-ODOO-17/NGINX/logs:/var/log/nginx
  - /efs/HLP-ERP-ODOO-17/NGINX/cache:/var/cache/nginx
```

## ⚙️ Configuración EFS

### En terraform.tfvars:
```bash
# EFS Configuration
existing_efs_id = "fs-1234567890abcdef0"  # Tu EFS ID
efs_mount_point = "/efs"                  # Punto de montaje base
```

### Resultado:
- EFS se monta en `/efs`
- Proyecto se crea en `/efs/HLP-ERP-ODOO-17/`
- Estructura completa se inicializa automáticamente

## 🔄 Persistencia de Datos

### Con EFS:
- ✅ **Datos sobreviven** a recreación de instancias
- ✅ **Backups automáticos** de AWS
- ✅ **Acceso concurrente** desde múltiples instancias
- ✅ **Escalabilidad automática**

### Sin EFS (local):
- ⚠️ **Datos se pierden** al recrear instancia
- ✅ **Mejor rendimiento** (almacenamiento local)
- ✅ **Menores costos** (no paga por EFS)

## 📁 Archivos Importantes

### Configuración Odoo: `/efs/HLP-ERP-ODOO-17/ODOO/config/odoo.conf`
### Backups: `/efs/HLP-ERP-ODOO-17/POSTGRESQL/backups/`
### Logs PostgreSQL: `/efs/HLP-ERP-ODOO-17/POSTGRESQL/logs/`
### Logs Odoo: `/efs/HLP-ERP-ODOO-17/ODOO/logs/`
### SSL Certificates: `/efs/HLP-ERP-ODOO-17/NGINX/ssl/`

## 🚀 Comandos Útiles

```bash
# Ver estructura completa
find /efs/HLP-ERP-ODOO-17 -type d | sort

# Ver tamaño por servicio
du -sh /efs/HLP-ERP-ODOO-17/*/

# Acceder a logs
tail -f /efs/HLP-ERP-ODOO-17/ODOO/logs/odoo.log
tail -f /efs/HLP-ERP-ODOO-17/POSTGRESQL/logs/postgresql.log
tail -f /efs/HLP-ERP-ODOO-17/NGINX/logs/access.log

# Backup manual
docker exec odoo_postgresql pg_dump -U odoo odoo | gzip > /efs/HLP-ERP-ODOO-17/POSTGRESQL/backups/manual_$(date +%Y%m%d_%H%M%S).sql.gz
```

## 🔧 Mantenimiento

### Backup Selectivo:
```bash
# Solo PostgreSQL
tar -czf postgresql_backup.tar.gz /efs/HLP-ERP-ODOO-17/POSTGRESQL/

# Solo configuración Odoo
tar -czf odoo_config_backup.tar.gz /efs/HLP-ERP-ODOO-17/ODOO/config/

# Solo SSL certificates
tar -czf ssl_backup.tar.gz /efs/HLP-ERP-ODOO-17/NGINX/ssl/
```

### Limpieza de Logs:
```bash
# Logs antiguos de Nginx (>30 días)
find /efs/HLP-ERP-ODOO-17/NGINX/logs/ -name "*.log" -mtime +30 -delete

# Backups antiguos (>7 días)
find /efs/HLP-ERP-ODOO-17/POSTGRESQL/backups/ -name "*.sql.gz" -mtime +7 -delete
```

## ✅ Beneficios de esta Estructura

1. **📁 Organización Clara**: Cada servicio tiene su espacio dedicado
2. **🔄 Persistencia Granular**: Controla qué persiste y qué no
3. **📊 Monitoreo Específico**: Logs separados por servicio
4. **🔧 Mantenimiento Fácil**: Backup/restore selectivo
5. **📈 Escalabilidad**: Fácil migración entre instancias
6. **🔒 Seguridad**: Permisos granulares por directorio
