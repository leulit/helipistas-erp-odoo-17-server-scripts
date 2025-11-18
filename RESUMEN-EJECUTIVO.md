# 📊 Resumen Ejecutivo - Helipistas Odoo 17

## 🎯 ¿Qué es este proyecto?

Sistema de despliegue automatizado de **Odoo 17 ERP** en AWS con infraestructura como código (Terraform), que permite crear desde cero un servidor Odoo completamente funcional con SSL/HTTPS en **10-12 minutos** con un solo comando.

---

## 🏗️ Arquitectura en 30 Segundos

```
AWS (eu-west-1)
├── EC2 Instance (t3.medium, Amazon Linux 2)
│   ├── Docker: PostgreSQL 15
│   ├── Docker: Odoo 17
│   ├── Docker: Nginx (Proxy + SSL)
│   └── Docker: Certbot (Let's Encrypt)
├── EFS (fs-ec7152d9) → Datos persistentes
├── Elastic IP (54.228.16.152) → IP fija
└── VPC + Security Group → Red y firewall
```

**URL de acceso**: https://erp17.helipistas.com

---

## ⚡ Quick Start

### Para Desplegar

```bash
cd terraform
terraform destroy -auto-approve && terraform apply -auto-approve
```

Esperar **10-12 minutos** → Odoo listo en https://erp17.helipistas.com

### Para Conectarse

```bash
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
```

### Para Ver Servicios

```bash
cd /efs/HELIPISTAS-ODOO-17
docker-compose ps
```

---

## 📁 Archivos Clave

| Archivo | Descripción | Cuándo Modificar |
|---------|-------------|------------------|
| `terraform/main.tf` | Define infraestructura AWS | Cambiar recursos AWS |
| `terraform/variables.tf` | Variables de configuración | Agregar nuevas variables |
| `terraform/terraform.tfvars` | Valores de configuración **PRIVADO** | Cambiar contraseñas, IPs |
| `terraform/user_data_simple.sh` | Setup inicial de EC2 | Cambiar dependencias del sistema |
| `setup_odoo_complete.sh` | Configuración completa (en GitHub) | Cambiar Odoo, Nginx, SSL |

---

## 🔑 Recursos AWS (NO se eliminan con Terraform)

Estos recursos **existen previamente** y se **reutilizan**:

| Recurso | ID | Descripción |
|---------|-----|-------------|
| **VPC** | vpc-92d074f6 | Red virtual privada |
| **Subnet** | subnet-c362e2a7 | Subred pública en eu-west-1b |
| **EFS** | fs-ec7152d9 | Almacenamiento persistente |
| **Elastic IP** | eipalloc-0184418cc26d4e66f | IP pública: 54.228.16.152 |
| **Key Pair** | ERP | Par de claves SSH |

⚠️ **IMPORTANTE**: Destruir infraestructura con `terraform destroy` **NO** elimina estos recursos.

---

## 🔄 Flujo de Deployment

```
terraform apply
    ↓
Crea EC2 Instance
    ↓
Ejecuta user_data_simple.sh
    ↓
Instala Docker, AWS CLI, NFS utils
    ↓
Monta EFS en /efs
    ↓
Descarga setup_odoo_complete.sh desde GitHub
    ↓
Ejecuta setup_odoo_complete.sh
    ↓
Crea docker-compose.yml
    ↓
Crea configuración de Nginx (HTTP)
    ↓
Crea configuración de Odoo
    ↓
Inicia PostgreSQL, Odoo, Nginx
    ↓
Obtiene certificado SSL de Let's Encrypt
    ↓
Reconfigura Nginx para HTTPS
    ↓
Inicia servicio certbot (auto-renovación)
    ↓
✅ Sistema listo: https://erp17.helipistas.com
```

---

## 💾 Datos Persistentes (EFS)

```
/efs/HELIPISTAS-ODOO-17/
├── postgres/        → Base de datos PostgreSQL
├── odoo/
│   ├── conf/       → odoo.conf
│   ├── addons/     → Módulos custom
│   ├── filestore/  → Archivos de usuarios
│   └── sessiones/  → Sesiones activas
├── nginx/
│   └── conf/       → default.conf
└── certbot/
    └── conf/       → Certificados SSL
        └── live/erp17.helipistas.com/
```

**Ventaja**: Si destruyes y recreas la EC2, **todos los datos permanecen** en EFS.

---

## 🔐 Credenciales

### PostgreSQL
- **Host**: postgresOdoo16 (dentro de Docker)
- **Usuario**: odoo
- **Contraseña**: Ver `terraform/terraform.tfvars` → `postgres_password`
- **Base de datos**: postgres

### Odoo Master Password
- **Contraseña**: Ver `terraform/terraform.tfvars` → `odoo_master_password`
- **Uso**: Crear/eliminar bases de datos en Odoo UI

### SSH
- **Archivo PEM**: `/Users/emiloalvarez/Work/PEMFiles/ERP.pem`
- **Usuario**: ec2-user
- **IP**: 54.228.16.152

---

## 🛠️ Comandos Más Usados

### Gestión de Infraestructura

```bash
# Ver plan de cambios
terraform plan

# Aplicar cambios
terraform apply

# Destruir infraestructura
terraform destroy

# Ver outputs
terraform output
```

### Gestión de Servicios (en el servidor)

```bash
# Ver estado
docker-compose ps

# Ver logs
docker-compose logs -f

# Reiniciar Odoo
docker-compose restart helipistas_odoo

# Reiniciar todo
docker-compose restart

# Parar todo
docker-compose down

# Iniciar todo
docker-compose up -d
```

---

## 🐛 Troubleshooting Rápido

### Odoo no responde

```bash
docker logs helipistas_odoo
docker-compose restart helipistas_odoo
```

### SSL no funciona

```bash
docker logs helipistas_certbot
nslookup erp17.helipistas.com  # Debe resolver a 54.228.16.152
```

### PostgreSQL no funciona

```bash
docker logs helipistas_postgres
docker exec helipistas_postgres pg_isready -U odoo
```

### Ver logs de deployment

```bash
sudo tail -f /var/log/cloud-init-output.log
sudo tail -f /var/log/odoo-setup-complete.log
```

---

## 📚 Documentación Disponible

| Archivo | Para Quién | Contenido |
|---------|-----------|-----------|
| `README-COMPLETO.md` | **Todos** | Documentación exhaustiva del proyecto |
| `GUIA-RAPIDA.md` | **Administradores** | Comandos del día a día |
| `GUIA-DESARROLLADORES.md` | **Desarrolladores** | Arquitectura técnica, cómo modificar |
| `RESUMEN-EJECUTIVO.md` | **Nuevos al proyecto** | Este archivo - visión general |

---

## 🔄 Para Nuevos Desarrolladores

### 1. Entender el proyecto (1-2 horas)

```bash
# Clonar repositorio
git clone https://github.com/leulit/helipistas-erp-odoo-17-server-scripts.git

# Leer documentación en este orden:
1. RESUMEN-EJECUTIVO.md (este archivo) - 10 min
2. README-COMPLETO.md - 30-45 min
3. GUIA-RAPIDA.md - 15 min
4. GUIA-DESARROLLADORES.md - 30-45 min

# Revisar archivos clave:
- terraform/main.tf
- terraform/variables.tf
- terraform/user_data_simple.sh
- setup_odoo_complete.sh
```

### 2. Configurar ambiente local (30 min)

```bash
# Instalar herramientas
brew install awscli terraform

# Configurar AWS CLI
aws configure

# Obtener archivo PEM (si no lo tienes)
# Contactar administrador para obtener ERP.pem

# Probar conexión
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152
```

### 3. Primer deployment de prueba (15 min)

```bash
cd terraform

# Crear terraform.tfvars (copiar de terraform.tfvars.example)
cp terraform.tfvars.example terraform.tfvars

# IMPORTANTE: Cambiar resource_prefix para no afectar producción
# En terraform.tfvars:
# resource_prefix = "PRUEBAS-NOMBRE"

# Desplegar
terraform init
terraform apply

# Verificar
curl -I https://erp17.helipistas.com

# Destruir prueba
terraform destroy
```

### 4. Modificar el proyecto (según necesidad)

**Escenario A: Cambiar configuración de Odoo**

1. Editar `setup_odoo_complete.sh` (sección 5)
2. Commit y push a GitHub
3. `terraform destroy && terraform apply`

**Escenario B: Agregar nuevo contenedor**

1. Editar `setup_odoo_complete.sh` (sección 2 - docker-compose)
2. Agregar directorio en `user_data_simple.sh` (sección 5)
3. Commit y push a GitHub
4. `terraform destroy && terraform apply`

**Escenario C: Cambiar recursos AWS**

1. Editar `terraform/main.tf`
2. `terraform plan` para ver cambios
3. `terraform apply`

---

## ⚠️ Consideraciones Importantes

### Seguridad

- ❌ **NUNCA** subir `terraform.tfvars` a Git (contiene contraseñas)
- ✅ Usar contraseñas fuertes generadas con `openssl rand -base64 32`
- ✅ Archivo PEM con permisos 400: `chmod 400 ERP.pem`
- ✅ Certificados SSL se renuevan automáticamente cada 12 horas

### Costos

- **EC2 t3.medium**: ~$0.0416/hora = ~$30/mes (On-Demand)
- **EFS**: ~$0.30/GB/mes (solo pagas lo que usas)
- **Elastic IP**: Gratis mientras esté asociada
- **Data transfer**: Primeros 100GB gratis/mes

**Total estimado**: $30-40/mes

### Backups

- **EFS**: AWS hace backups automáticos (punto de restauración)
- **Manual**: Hacer `pg_dumpall` periódicamente
- **Recomendado**: Configurar backup automático a S3

---

## 🎯 Casos de Uso Comunes

### Caso 1: Recrear infraestructura completamente

```bash
cd terraform
terraform destroy -auto-approve && terraform apply -auto-approve
# Esperar 10-12 minutos
# Datos permanecen en EFS, infraestructura nueva
```

### Caso 2: Actualizar configuración de Odoo

```bash
# 1. Editar setup_odoo_complete.sh en GitHub
# 2. Recrear infraestructura
terraform destroy -auto-approve && terraform apply -auto-approve
```

### Caso 3: Acceder a base de datos

```bash
# SSH al servidor
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Acceder a PostgreSQL
docker exec -it helipistas_postgres psql -U odoo

# O hacer query directa
docker exec helipistas_postgres psql -U odoo -c "SELECT * FROM res_users LIMIT 5;"
```

### Caso 4: Instalar módulo custom en Odoo

```bash
# SSH al servidor
ssh -i /Users/emiloalvarez/Work/PEMFiles/ERP.pem ec2-user@54.228.16.152

# Copiar módulo a addons
sudo cp -r /ruta/modulo /efs/HELIPISTAS-ODOO-17/odoo/addons/

# Corregir permisos
sudo chown -R 101:101 /efs/HELIPISTAS-ODOO-17/odoo/addons/

# Reiniciar Odoo
cd /efs/HELIPISTAS-ODOO-17
docker-compose restart helipistas_odoo

# En Odoo UI: Apps → Update Apps List
```

---

## 🔗 Links Útiles

- **Repositorio GitHub**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts
- **Odoo 17 Docs**: https://www.odoo.com/documentation/17.0/
- **Terraform AWS Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **Let's Encrypt**: https://letsencrypt.org/docs/

---

## 📞 Contacto y Soporte

- **Issues GitHub**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/issues
- **Pull Requests**: Para contribuir al proyecto

---

## ✅ Checklist para Nuevo Desarrollador

- [ ] Leer RESUMEN-EJECUTIVO.md (este archivo)
- [ ] Leer README-COMPLETO.md
- [ ] Instalar AWS CLI y Terraform
- [ ] Configurar credenciales de AWS
- [ ] Obtener archivo PEM (ERP.pem)
- [ ] Clonar repositorio
- [ ] Revisar archivos clave (main.tf, variables.tf, scripts)
- [ ] Hacer primer deployment de prueba
- [ ] Conectarse al servidor por SSH
- [ ] Ver logs y servicios
- [ ] Leer GUIA-DESARROLLADORES.md para modificaciones

---

**Este resumen te da todo lo esencial para entender y trabajar con el proyecto en 15-20 minutos.** 🚀

Para detalles técnicos profundos, consulta los otros archivos de documentación.
