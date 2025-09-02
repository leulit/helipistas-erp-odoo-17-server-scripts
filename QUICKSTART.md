# Guía de Inicio Rápido - Helipistas ERP

## ⚡ Despliegue en 5 Minutos

### 1. Preparación (1 minuto)

```bash
# Verificar prerequisitos
./deploy.sh --check

# Si falta algo:
# - Instalar Terraform: https://terraform.io/downloads
# - Instalar AWS CLI: https://aws.amazon.com/cli/
# - Configurar AWS: aws configure
```

### 2. Configuración (2 minutos)

```bash
# Editar configuración del proyecto:
nano terraform/terraform.tfvars
```

**Variables OBLIGATORIAS** a cambiar en `terraform.tfvars`:

```hcl
# Clave SSH - Usa tu Key Pair existente de AWS (REQUERIDO)
key_pair_name = "mi-clave-aws"  # Nombre de tu Key Pair en AWS (sin .pem)

# Contraseñas seguras (REQUERIDO)
odoo_master_password = "tu_contraseña_master_muy_segura"
postgres_password = "tu_contraseña_postgres_muy_segura"

# Tu IP para SSH (RECOMENDADO por seguridad)
allowed_ssh_cidr = "TU_IP_PUBLICA/32"  # Obtener con: curl ifconfig.me
```

**📝 Sobre las Claves SSH:**
- Usa el **nombre** de tu Key Pair de AWS (no el archivo .pem)
- Si tu archivo se llama `mi-clave.pem`, el nombre del Key Pair es `mi-clave`
- Para conectarte usarás: `ssh -i ~/.ssh/mi-clave.pem ec2-user@IP`
- Consulta tus Key Pairs en: AWS Console → EC2 → Key Pairs

### 3. Despliegue (2 minutos)

```bash
# Despliegue automático completo
./deploy.sh

# Al final verás:
# ✅ IP de la instancia: X.X.X.X
# ✅ URL de Odoo: http://X.X.X.X
# ✅ Comando SSH: ssh -i ~/.ssh/mi-clave-aws.pem ec2-user@X.X.X.X
```

### 4. Verificación (30 segundos)

```bash
# Verificar que todo funciona
./manage.sh status

# Acceder a Odoo en el navegador
# http://IP_DE_TU_INSTANCIA
```

---

## 🔧 Configuración Post-Despliegue

### Configurar SSL (Opcional pero Recomendado)

Si tienes un dominio:

```bash
# Configurar automáticamente SSL con Let's Encrypt
./manage.sh setup-ssl tudominio.com admin@tudominio.com
```

### Primera Configuración de Odoo

1. Abre `http://IP_DE_TU_INSTANCIA` en el navegador
2. Crea la primera base de datos:
   - **Database Name**: `production` (o tu nombre preferido)
   - **Email**: tu email de administrador
   - **Password**: tu contraseña de administrador
   - **Phone**: opcional
   - **Language**: Español
   - **Country**: México
   - **Demo data**: No (para producción)

### Comandos Útiles Post-Despliegue

```bash
# Ver estado de servicios
./manage.sh status

# Ver logs en tiempo real
./manage.sh logs

# Crear backup manual
./manage.sh backup

# Conectar por SSH
./manage.sh ssh

# Ver información de conexión
./manage.sh info
```

---

## 🚨 Solución de Problemas Comunes

### Error: "No se pudo obtener la IP de la instancia"

```bash
# Verificar que Terraform se ejecutó correctamente
cd terraform
terraform output

# Si no hay outputs, re-ejecutar despliegue
cd ..
./deploy.sh --deploy
```

### Error: "Odoo no responde"

```bash
# Esperar 5-10 minutos (la instancia puede estar configurándose)
# Luego verificar:
./manage.sh status

# Si persiste:
./manage.sh logs odoo
```

### Error: "Permission denied" en SSH

```bash
# Verificar que tienes la clave SSH correcta
ls -la ~/.ssh/

# Generar nueva clave si es necesario
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Actualizar terraform.tfvars con la nueva clave pública
cat ~/.ssh/id_rsa.pub
```

### Error: "AWS credentials not configured"

```bash
# Configurar AWS CLI
aws configure

# Verificar configuración
aws sts get-caller-identity
```

---

## 📋 Checklist de Despliegue Exitoso

- [ ] ✅ Prerequisites instalados (Terraform, AWS CLI)
- [ ] ✅ AWS CLI configurado (`aws sts get-caller-identity`)
- [ ] ✅ Clave SSH generada (`cat ~/.ssh/id_rsa.pub`)
- [ ] ✅ `terraform.tfvars` configurado con valores reales
- [ ] ✅ Despliegue ejecutado sin errores (`./deploy.sh`)
- [ ] ✅ Archivo `deployment-info.txt` creado
- [ ] ✅ SSH funciona (`./manage.sh ssh`)
- [ ] ✅ Odoo responde (`./manage.sh status`)
- [ ] ✅ Acceso web funciona (abrir URL en navegador)
- [ ] ✅ Primera base de datos creada en Odoo
- [ ] ✅ Backup automático configurado
- [ ] ✅ SSL configurado (si tienes dominio)

---

## 💡 Consejos Pro

### Para Desarrollo

```bash
# Usar instancia más pequeña
instance_type = "t3.small"  # En terraform.tfvars

# Precio spot más bajo
spot_price = "0.02"  # En terraform.tfvars
```

### Para Producción

```bash
# Instancia más robusta
instance_type = "t3.medium"  # o t3.large

# Disco más grande
root_volume_size = 50  # GB

# Configurar dominio y SSL
domain_name = "odoo.tuempresa.com"
letsencrypt_email = "admin@tuempresa.com"
```

### Monitoreo

```bash
# Configurar alertas (opcional)
export WEBHOOK_URL="https://hooks.slack.com/..."
./manage.sh remote 'echo "*/5 * * * * /opt/odoo/monitor.sh" | crontab -'
```

---

**🎉 ¡Listo!** Tu servidor Odoo está funcionando en AWS con:
- ✅ Spot Instance (ahorro 60-90%)
- ✅ Docker con auto-restart
- ✅ Nginx proxy con caché
- ✅ PostgreSQL optimizado
- ✅ Backups automáticos
- ✅ SSL opcional
- ✅ Monitoreo incluido
