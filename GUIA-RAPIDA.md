# ⚡ Guía Rápida - Helipistas Odoo 17

## 🚀 Comandos Más Usados

### Desplegar Infraestructura

```bash
cd terraform
terraform init
terraform destroy -auto-approve && terraform apply -auto-approve
```

⏱️ **Tiempo**: 10-12 minutos

---

### Conectarse al Servidor

```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
```

---

### Ver Estado de Servicios

```bash
cd /efs/HELIPISTAS-ODOO-17
docker-compose ps
```

---

### Ver Logs en Tiempo Real

```bash
# Todos los servicios
docker-compose logs -f

# Solo Odoo
docker-compose logs -f helipistas_odoo

# Solo PostgreSQL
docker-compose logs -f postgresOdoo16

# Solo Nginx
docker-compose logs -f nginx
```

---

### Reiniciar Servicios

```bash
cd /efs/HELIPISTAS-ODOO-17

# Reiniciar Odoo
docker-compose restart helipistas_odoo

# Reiniciar todos
docker-compose restart

# Parar todos
docker-compose down

# Iniciar todos
docker-compose up -d
```

---

### Verificar Certificado SSL

```bash
# Ver información del certificado
docker run --rm \
  -v /efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt \
  certbot/certbot certificates

# Renovar manualmente
docker run --rm \
  -v /efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot \
  -v /efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt \
  certbot/certbot renew --force-renewal --non-interactive

# Reiniciar Nginx después de renovar
docker-compose restart nginx
```

---

### Ver Logs del Sistema

```bash
# Logs de cloud-init (setup inicial)
sudo tail -f /var/log/cloud-init-output.log

# Logs del setup completo
sudo tail -f /var/log/odoo-setup-complete.log

# Logs del sistema
sudo journalctl -f
```

---

### Verificar Recursos

```bash
# CPU, RAM, Disco
docker stats

# Espacio en disco
df -h

# Montaje de EFS
df -h | grep efs
mount | grep efs
```

---

### Backup Manual

```bash
# Conectarse al servidor
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Crear backup de PostgreSQL
cd /efs/HELIPISTAS-ODOO-17
docker exec helipistas_postgres pg_dumpall -U odoo > backup_$(date +%Y%m%d_%H%M%S).sql

# Backup de archivos de Odoo
tar -czf odoo_filestore_$(date +%Y%m%d_%H%M%S).tar.gz odoo/filestore/
```

---

### Acceder a PostgreSQL

```bash
# Desde el servidor
docker exec -it helipistas_postgres psql -U odoo

# Comandos útiles en psql:
\l              # Listar bases de datos
\c nombre_db    # Conectar a una base de datos
\dt             # Listar tablas
\q              # Salir
```

---

### Acceder al Contenedor de Odoo

```bash
docker exec -it helipistas_odoo bash

# Dentro del contenedor:
odoo shell -d nombre_base_datos  # Shell de Odoo
exit                              # Salir
```

---

## 🔧 Solución Rápida de Problemas

### Odoo no responde

```bash
# Ver logs
docker logs helipistas_odoo

# Reiniciar
docker-compose restart helipistas_odoo
```

### PostgreSQL no responde

```bash
# Ver logs
docker logs helipistas_postgres

# Reiniciar
docker-compose restart postgresOdoo16
```

### Nginx no responde

```bash
# Ver logs
docker logs helipistas_nginx

# Ver configuración
cat /efs/HELIPISTAS-ODOO-17/nginx/conf/default.conf

# Reiniciar
docker-compose restart nginx
```

### Certificado SSL expirado

```bash
# Renovar
docker run --rm \
  -v /efs/HELIPISTAS-ODOO-17/certbot/www:/var/www/certbot \
  -v /efs/HELIPISTAS-ODOO-17/certbot/conf:/etc/letsencrypt \
  certbot/certbot renew --force-renewal --non-interactive

# Reiniciar Nginx
docker-compose restart nginx
```

### DNS no resuelve

```bash
# Verificar DNS
nslookup erp17.helipistas.com
# Debe resolver a: 54.228.16.152
```

---

## 📍 URLs de Acceso

| URL | Uso |
|-----|-----|
| https://erp17.helipistas.com | **Acceso principal** (HTTPS con SSL) |
| http://erp17.helipistas.com | Redirige automáticamente a HTTPS |
| http://54.228.16.152:8069 | Acceso directo a Odoo (solo desarrollo) |

---

## 🔑 Credenciales

### PostgreSQL
- **Host**: postgresOdoo16 (dentro de Docker) o localhost:5432 (desde servidor)
- **Usuario**: odoo
- **Contraseña**: Ver `terraform.tfvars` (variable `postgres_password`)
- **Base de datos**: postgres (por defecto)

### Odoo Master Password
- **Contraseña**: Ver `terraform.tfvars` (variable `odoo_master_password`)
- **Uso**: Crear/eliminar bases de datos en Odoo

---

## 📂 Ubicaciones Importantes

| Descripción | Ruta |
|-------------|------|
| **Proyecto completo** | `/efs/HELIPISTAS-ODOO-17/` |
| **Base de datos** | `/efs/HELIPISTAS-ODOO-17/postgres/pgdata/` |
| **Archivos de Odoo** | `/efs/HELIPISTAS-ODOO-17/odoo/filestore/` |
| **Configuración Odoo** | `/efs/HELIPISTAS-ODOO-17/odoo/conf/odoo.conf` |
| **Certificados SSL** | `/efs/HELIPISTAS-ODOO-17/certbot/conf/live/erp17.helipistas.com/` |
| **Configuración Nginx** | `/efs/HELIPISTAS-ODOO-17/nginx/conf/default.conf` |
| **docker-compose.yml** | `/efs/HELIPISTAS-ODOO-17/docker-compose.yml` |

---

## ⚠️ Recordatorios Importantes

1. **EFS contiene TODOS los datos**: No eliminar nada de `/efs/HELIPISTAS-ODOO-17/`
2. **Terraform.tfvars tiene contraseñas**: Nunca subirlo a Git
3. **Archivo PEM es crítico**: Sin él no puedes conectarte por SSH
4. **Elastic IP es fija**: 54.228.16.152 (no cambia)
5. **EFS es compartido**: Múltiples instancias pueden montarlo

---

## 🆘 Ayuda Adicional

- **README completo**: `README.md` en el repositorio
- **Documentación técnica**: Secciones detalladas en README.md
- **Issues GitHub**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/issues
