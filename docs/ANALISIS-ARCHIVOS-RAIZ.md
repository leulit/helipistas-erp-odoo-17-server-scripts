# 📂 Análisis de Archivos en Raíz vs deployments/on-demand

## ❓ Pregunta

¿Son necesarios los archivos/carpetas en raíz o con `deployments/on-demand/` es suficiente?

---

## ✅ Respuesta Rápida

**SÍ, el archivo `setup_odoo_complete.sh` en raíz ES NECESARIO** porque:

1. **Se descarga desde GitHub** durante el deployment
2. El script `user_data_simple.sh` ejecuta:
   ```bash
   curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/setup_odoo_complete.sh
   ```

**Las demás carpetas/archivos en raíz NO son necesarios** para el deployment, son legacy o desarrollo local.

---

## 📊 Análisis Detallado

### 🟢 NECESARIOS (Deben estar en raíz del repositorio)

| Archivo | Ubicación | Por qué es necesario |
|---------|-----------|---------------------|
| **`setup_odoo_complete.sh`** | Raíz | ✅ Se descarga desde GitHub en runtime |
| `.gitignore` | Raíz | ✅ Control de versiones |
| `LICENSE` | Raíz | ✅ Licencia del proyecto |
| Documentación (*.md) | Raíz | ✅ Para GitHub y desarrolladores |

---

### 🔴 NO NECESARIOS (Legacy o desarrollo local)

| Archivo/Carpeta | Ubicación | Status | Usar en su lugar |
|----------------|-----------|--------|------------------|
| **`terraform/`** | Raíz | 🟡 DUPLICADO | `deployments/on-demand/terraform/` |
| **`docker/`** | Raíz | ❌ NO SE USA | Se genera en runtime por `setup_odoo_complete.sh` |
| **`scripts/`** | Raíz | ❌ NO SE USA | Scripts de utilidad local |
| `cleanup.sh` | Raíz | ❌ NO SE USA | Script local |
| `deploy.sh` | Raíz | ❌ NO SE USA | Script legacy |
| `diagnose-instance.sh` | Raíz | ❌ NO SE USA | Utilidad local |
| `diagnose_efs.sh` | Raíz | ❌ NO SE USA | Utilidad local |
| `manage.sh` | Raíz | ❌ NO SE USA | Utilidad local |
| `setup-odoo.sh` | Raíz | ❌ NO SE USA | Script legacy |
| `test_efs_mount.sh` | Raíz | ❌ NO SE USA | Utilidad local |
| `terraform.tfstate` | Raíz | ⚠️ PELIGROSO | Debería estar en `.gitignore` |

---

## 🔍 Análisis del Flujo de Deployment

### Paso 1: Terraform Apply

```bash
cd deployments/on-demand/terraform
terraform apply
```

**Usa**:
- ✅ `deployments/on-demand/terraform/main-simple.tf`
- ✅ `deployments/on-demand/terraform/user_data_simple.sh`
- ✅ `deployments/on-demand/terraform/variables-simple.tf`
- ✅ `deployments/on-demand/terraform/outputs-simple.tf`

**NO usa**:
- ❌ `terraform/` en raíz (es duplicado)
- ❌ `docker/` en raíz

---

### Paso 2: EC2 Boot (user_data_simple.sh)

**Ubicación en EC2**: `/var/lib/cloud/instances/.../user-data.txt`

**Línea clave** (línea 150):
```bash
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/setup_odoo_complete.sh
```

**Descarga desde GitHub**:
- ✅ `setup_odoo_complete.sh` **desde la raíz del repositorio en GitHub**

**NO descarga**:
- ❌ Nada de `docker/` (se genera en runtime)
- ❌ Nada de `scripts/` (no se necesita)

---

### Paso 3: Setup Completo (setup_odoo_complete.sh)

**Se ejecuta en**: `/efs/HELIPISTAS-ODOO-17/`

**Genera en runtime**:
```bash
cat > docker-compose.yml << EOF
# ... genera el contenido completo
EOF
```

**Genera**:
- ✅ `docker-compose.yml` (en EFS, NO desde repo)
- ✅ `nginx.conf` (en EFS, NO desde repo)
- ✅ `odoo.conf` (en EFS, NO desde repo)

**NO usa**:
- ❌ `docker/docker-compose.yml` del repositorio
- ❌ Nada de la carpeta `docker/` del repositorio

---

## 📦 Contenido de Carpetas en Raíz

### `docker/` (NO SE USA en deployment)

```
docker/
├── .env.example
├── config/
├── docker-compose.yml    ← ❌ NO se usa, se genera en runtime
└── nginx/
```

**Propósito**: Desarrollo local o legacy

**¿Se usa en deployment?**: ❌ NO

**Razón**: `setup_odoo_complete.sh` genera `docker-compose.yml` dinámicamente en `/efs/HELIPISTAS-ODOO-17/`

---

### `scripts/` (NO SE USA en deployment)

```
scripts/
├── backup.sh     ← Utilidad local
├── monitor.sh    ← Utilidad local
└── restore.sh    ← Utilidad local
```

**Propósito**: Scripts de utilidad para operaciones manuales

**¿Se usa en deployment?**: ❌ NO

**Uso**: Ejecutar manualmente después de conectarse por SSH

---

### `terraform/` (DUPLICADO)

```
terraform/
├── main-simple.tf
├── user_data_simple.sh
├── ...
```

**Estado**: 🟡 DUPLICADO

**Original**: `deployments/on-demand/terraform/`

**¿Se usa en deployment?**: ❌ NO (se usa la copia en `deployments/on-demand/`)

---

## 🎯 Conclusión

### ¿Con `deployments/on-demand/` es suficiente para desplegar?

**Casi**, pero falta 1 archivo crítico:

#### ✅ Sí, si:

1. **`setup_odoo_complete.sh` está en raíz del repositorio GitHub**
   - Porque `user_data_simple.sh` lo descarga con:
   ```bash
   curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/.../main/setup_odoo_complete.sh
   ```

2. **Tienes acceso a GitHub desde la EC2**
   - La instancia EC2 puede descargar desde `raw.githubusercontent.com`

#### ❌ No necesitas:

- `terraform/` en raíz (usa `deployments/on-demand/terraform/`)
- `docker/` en raíz (se genera dinámicamente)
- `scripts/` en raíz (son utilidades manuales)
- Otros scripts `.sh` en raíz (legacy)

---

## 🔄 Flujo de Descarga desde GitHub

```
┌─────────────────────────────────────────────────────────────┐
│  1. Terraform Apply (LOCAL)                                 │
│     cd deployments/on-demand/terraform                      │
│     terraform apply                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  2. EC2 Boot - user_data_simple.sh (EN AWS)                 │
│     Ejecuta automáticamente al arrancar                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Descarga desde GitHub (EN AWS)                          │
│     curl -o setup_odoo_complete.sh \                        │
│       https://raw.githubusercontent.com/.../main/setup...   │
│                                                              │
│     ✅ Descarga: setup_odoo_complete.sh                     │
│     ❌ NO descarga: docker/, scripts/, terraform/           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Ejecuta setup_odoo_complete.sh (EN AWS)                 │
│     ./setup_odoo_complete.sh $PASS1 $PASS2 $DOMAIN          │
│                                                              │
│     Genera en EFS:                                          │
│     - docker-compose.yml                                    │
│     - nginx.conf                                            │
│     - odoo.conf                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚠️ Archivo Crítico en Raíz

### `setup_odoo_complete.sh`

**Ubicación REQUERIDA**: Raíz del repositorio GitHub

**URL de descarga**:
```
https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/setup_odoo_complete.sh
```

**¿Por qué en raíz?**:
- `user_data_simple.sh` asume que está en `/main/setup_odoo_complete.sh`
- Cambiar la ubicación requeriría modificar `user_data_simple.sh`

**Estado actual**:
- ✅ Existe en raíz: `/setup_odoo_complete.sh`
- ✅ Existe copia en: `/deployments/on-demand/setup_odoo_complete.sh`
- ✅ Ambos son idénticos (mismos 426 líneas)

---

## 🧹 Limpieza Recomendada

### Archivos/Carpetas que PUEDES eliminar de raíz:

```bash
# ❌ Eliminar (no se usan en deployment)
rm -rf docker/
rm -rf scripts/
rm -rf terraform/          # Duplicado, usa deployments/on-demand/terraform/
rm cleanup.sh
rm deploy.sh
rm diagnose-instance.sh
rm diagnose_efs.sh
rm manage.sh
rm setup-odoo.sh
rm test_efs_mount.sh
rm terraform.tfstate       # ⚠️ Nunca debería estar en Git
```

### Archivos que DEBES mantener en raíz:

```bash
# ✅ Mantener (necesarios)
setup_odoo_complete.sh     # ← CRÍTICO: Se descarga desde GitHub
.gitignore
LICENSE
README-COMPLETO.md
GUIA-RAPIDA.md
GUIA-DESARROLLADORES.md
DECISIONES-ARQUITECTURA.md
INDICE-DOCUMENTACION.md
RESUMEN-EJECUTIVO.md
REORGANIZACION-DEPLOYMENTS.md
TERRAFORM_VS_AWS_CLI.md
deployments/               # ← Toda esta carpeta
```

---

## 🔐 Actualización de .gitignore

**Agregar a `.gitignore`**:

```gitignore
# Terraform state (NUNCA en Git)
terraform.tfstate
terraform.tfstate.backup
*.tfstate
*.tfstate.*

# Terraform vars con secrets
terraform.tfvars
**/terraform.tfvars

# Terraform internals
.terraform/
.terraform.lock.hcl

# Logs
*.log

# Environment variables
.env
```

---

## ✅ Checklist de Deployment

### Para desplegar solo necesitas:

- [x] Carpeta `deployments/on-demand/terraform/` (con archivos .tf)
- [x] Archivo `setup_odoo_complete.sh` en raíz del repo GitHub
- [x] Acceso a GitHub desde EC2 (para descargar script)
- [x] Credenciales AWS configuradas localmente
- [x] Archivo `terraform.tfvars` con passwords (NO en Git)

### NO necesitas:

- [ ] `docker/` en raíz
- [ ] `scripts/` en raíz
- [ ] `terraform/` en raíz (es duplicado)
- [ ] Otros scripts `.sh` en raíz

---

## 🎯 Recomendaciones

### 1. Mantener Sincronizados

Los dos archivos `setup_odoo_complete.sh` deben ser idénticos:

```bash
# Raíz (se descarga desde GitHub)
/setup_odoo_complete.sh

# Copia en on-demand (para referencia)
/deployments/on-demand/setup_odoo_complete.sh
```

**Solución**: Crear symlink o script de sincronización

---

### 2. Modificar URL de Descarga (Opcional)

Si prefieres descargar desde `deployments/on-demand/`:

**Editar** `deployments/on-demand/terraform/user_data_simple.sh`:

```bash
# Actual:
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/setup_odoo_complete.sh

# Alternativa:
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/deployments/on-demand/setup_odoo_complete.sh
```

**Ventaja**: Eliminar `setup_odoo_complete.sh` de raíz

**Desventaja**: URL más larga, menos intuitiva

---

### 3. Limpieza del Repositorio

**Propuesta**:

```
SERVER-SCRIPTS/
├── deployments/
│   ├── on-demand/         ← TODO lo del deployment actual
│   └── spot/              ← Futuro
├── docs/                  ← Mover toda la documentación aquí
│   ├── README-COMPLETO.md
│   ├── GUIA-RAPIDA.md
│   └── ...
├── setup_odoo_complete.sh ← ÚNICO archivo .sh en raíz
├── .gitignore
├── LICENSE
└── README.md              ← README principal
```

**Eliminar**:
- `docker/`
- `scripts/`
- `terraform/`
- Scripts legacy

---

## 📞 Resumen Ejecutivo

### ¿Son necesarios los archivos en raíz?

| Archivo/Carpeta | ¿Necesario? | Razón |
|-----------------|-------------|-------|
| `setup_odoo_complete.sh` | ✅ **SÍ** | Se descarga desde GitHub |
| Documentación (*.md) | ✅ **SÍ** | Para GitHub |
| `deployments/` | ✅ **SÍ** | Contiene todo el deployment |
| `terraform/` | ❌ **NO** | Duplicado |
| `docker/` | ❌ **NO** | No se usa |
| `scripts/` | ❌ **NO** | Utilidades locales |
| Otros `.sh` | ❌ **NO** | Legacy |

### ¿Actualiza GitHub?

**SÍ**, cuando haces:

```bash
git add deployments/
git commit -m "Update deployment"
git push origin main
```

Entonces `user_data_simple.sh` puede descargar la última versión:

```bash
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/.../main/setup_odoo_complete.sh
```

**Delay**: GitHub raw tarda ~5 minutos en actualizar el cache después del push.

---

**Conclusión**: El contenido de `deployments/on-demand/` ES suficiente para desplegar, pero `setup_odoo_complete.sh` DEBE estar en raíz del repositorio porque se descarga desde GitHub durante el deployment.
