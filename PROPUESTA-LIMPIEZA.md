# 🧹 Propuesta de Limpieza del Repositorio

## 🎯 Objetivo

Eliminar archivos/carpetas redundantes o legacy que NO se usan en el deployment, manteniendo solo lo esencial.

---

## 📊 Estado Actual vs Propuesto

### ❌ Eliminar (No se usan en deployment)

```bash
# Carpetas
docker/                    # Se genera en runtime, no se usa
scripts/                   # Utilidades locales, no necesarias para deploy
terraform/                 # DUPLICADO de deployments/on-demand/terraform/

# Scripts legacy
cleanup.sh
deploy.sh
diagnose-instance.sh
diagnose_efs.sh
manage.sh
setup-odoo.sh
test_efs_mount.sh

# Estado de Terraform (NO debería estar en Git)
terraform.tfstate
terraform.tfstate.backup
```

### ✅ Mantener (Esenciales)

```bash
# Archivo CRÍTICO (se descarga desde GitHub)
setup_odoo_complete.sh     # ← user_data_simple.sh lo descarga en runtime

# Estructura de deployments
deployments/
  ├── on-demand/           # Deployment actual (producción)
  └── spot/                # Deployment futuro

# Documentación
README-COMPLETO.md
GUIA-RAPIDA.md
GUIA-DESARROLLADORES.md
DECISIONES-ARQUITECTURA.md
INDICE-DOCUMENTACION.md
RESUMEN-EJECUTIVO.md
REORGANIZACION-DEPLOYMENTS.md
ANALISIS-ARCHIVOS-RAIZ.md
TERRAFORM_VS_AWS_CLI.md

# Git
.gitignore
LICENSE
README-NUEVO.md            # ¿Renombrar a README.md?
```

---

## 🗂️ Estructura Propuesta

```
helipistas-erp-odoo-17-server-scripts/
├── .gitignore                         ← Actualizado
├── LICENSE
├── README.md                          ← Principal (renombrar README-NUEVO.md)
│
├── setup_odoo_complete.sh             ← CRÍTICO: Se descarga desde GitHub
│
├── deployments/                       ← Tipos de deployment
│   ├── README.md
│   ├── on-demand/                     ← Producción (EC2 On-Demand)
│   │   ├── README.md
│   │   ├── setup_odoo_complete.sh
│   │   └── terraform/
│   │       ├── main-simple.tf
│   │       ├── variables-simple.tf
│   │       ├── outputs-simple.tf
│   │       ├── user_data_simple.sh
│   │       ├── terraform.tfvars.example
│   │       └── ...
│   │
│   └── spot/                          ← Desarrollo (EC2 Spot - futuro)
│       └── README.md
│
└── docs/                              ← Toda la documentación
    ├── README-COMPLETO.md
    ├── GUIA-RAPIDA.md
    ├── GUIA-DESARROLLADORES.md
    ├── DECISIONES-ARQUITECTURA.md
    ├── INDICE-DOCUMENTACION.md
    ├── RESUMEN-EJECUTIVO.md
    ├── REORGANIZACION-DEPLOYMENTS.md
    ├── ANALISIS-ARCHIVOS-RAIZ.md
    └── TERRAFORM_VS_AWS_CLI.md
```

---

## 📝 Script de Limpieza

### Opción 1: Limpieza Conservadora (Recomendada)

Solo elimina lo claramente innecesario, mueve documentación:

```bash
#!/bin/bash
# cleanup_repo.sh

echo "🧹 Limpiando repositorio..."

# Crear carpeta docs
mkdir -p docs

# Mover documentación
echo "📚 Moviendo documentación a docs/..."
mv README-COMPLETO.md docs/
mv GUIA-RAPIDA.md docs/
mv GUIA-DESARROLLADORES.md docs/
mv DECISIONES-ARQUITECTURA.md docs/
mv INDICE-DOCUMENTACION.md docs/
mv RESUMEN-EJECUTIVO.md docs/
mv REORGANIZACION-DEPLOYMENTS.md docs/
mv ANALISIS-ARCHIVOS-RAIZ.md docs/
mv TERRAFORM_VS_AWS_CLI.md docs/

# Renombrar README principal
mv README-NUEVO.md README.md

# Eliminar duplicados y legacy
echo "🗑️  Eliminando archivos duplicados y legacy..."
rm -rf docker/
rm -rf scripts/
rm -rf terraform/     # Duplicado de deployments/on-demand/terraform/

# Eliminar scripts legacy
rm -f cleanup.sh
rm -f deploy.sh
rm -f diagnose-instance.sh
rm -f diagnose_efs.sh
rm -f manage.sh
rm -f setup-odoo.sh
rm -f test_efs_mount.sh

# Eliminar terraform state (NO debería estar en Git)
rm -f terraform.tfstate
rm -f terraform.tfstate.backup

echo "✅ Limpieza completada"
echo ""
echo "Estructura resultante:"
find . -maxdepth 2 -type f -name "*.md" -o -type f -name "*.sh" -o -type d -name "deployments" -o -type d -name "docs"
```

### Opción 2: Limpieza Agresiva

También elimina documentación legacy:

```bash
#!/bin/bash
# cleanup_repo_aggressive.sh

# Igual que Opción 1 pero también:
rm -f docs/TERRAFORM_VS_AWS_CLI.md       # Legacy
rm -f docs/REORGANIZACION-DEPLOYMENTS.md # Solo info histórica
rm -f docs/ANALISIS-ARCHIVOS-RAIZ.md     # Solo info histórica
```

---

## 🔄 Actualizar Referencias

### 1. Actualizar .gitignore

```gitignore
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Terraform vars (contienen secrets)
terraform.tfvars
**/terraform.tfvars

# Environment
.env
*.env

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/
*.swp
*.swo

# Backups
*.bak
*~
```

### 2. Actualizar INDICE-DOCUMENTACION.md

Cambiar rutas de documentación:

```diff
- [`README-COMPLETO.md`](README-COMPLETO.md)
+ [`README-COMPLETO.md`](docs/README-COMPLETO.md)
```

### 3. Actualizar README.md principal

Crear nuevo README.md con links actualizados:

```markdown
# 🚀 Helipistas ERP - Odoo 17 en AWS

Deployment automatizado de Odoo 17 en AWS con Terraform.

## 📦 Tipos de Despliegue

- **[On-Demand](deployments/on-demand/)** - Producción (100% disponibilidad, ~$30/mes)
- **[Spot Instances](deployments/spot/)** - Desarrollo (Ahorro 70%, ~$9/mes)

Ver comparativa: [deployments/README.md](deployments/README.md)

## 📚 Documentación

- **[Índice de documentación](docs/INDICE-DOCUMENTACION.md)** - ¿Qué documento leer?
- **[Guía rápida](docs/GUIA-RAPIDA.md)** - Comandos del día a día
- **[Documentación completa](docs/README-COMPLETO.md)** - Referencia técnica
- **[Guía desarrolladores](docs/GUIA-DESARROLLADORES.md)** - Modificar el proyecto
- **[Decisiones arquitectura](docs/DECISIONES-ARQUITECTURA.md)** - Por qué se decidió X

## 🚀 Quick Start

```bash
cd deployments/on-demand/terraform
terraform init
terraform apply
```

## 📄 Licencia

Ver [LICENSE](LICENSE)
```

---

## ⚠️ Consideraciones

### Archivos a mantener OBLIGATORIAMENTE

- ✅ `setup_odoo_complete.sh` en raíz
  - **Razón**: `user_data_simple.sh` lo descarga desde `main/setup_odoo_complete.sh`
  - **URL**: `https://raw.githubusercontent.com/leulit/.../main/setup_odoo_complete.sh`

### Alternativa: Cambiar URL de descarga

Si prefieres eliminar `setup_odoo_complete.sh` de raíz:

**1. Editar** `deployments/on-demand/terraform/user_data_simple.sh`:

```bash
# Cambiar línea 150:
curl -o setup_odoo_complete.sh https://raw.githubusercontent.com/leulit/helipistas-erp-odoo-17-server-scripts/main/deployments/on-demand/setup_odoo_complete.sh
```

**2. Eliminar** `setup_odoo_complete.sh` de raíz

**3. Mantener solo** `deployments/on-demand/setup_odoo_complete.sh`

---

## 📋 Checklist de Limpieza

### Pre-limpieza

- [ ] Hacer backup del repositorio
  ```bash
  cd ..
  cp -r SERVER-SCRIPTS SERVER-SCRIPTS.backup
  ```

- [ ] Verificar que no hay cambios sin commitear
  ```bash
  git status
  ```

- [ ] Crear branch para limpieza
  ```bash
  git checkout -b cleanup/repo-structure
  ```

### Durante limpieza

- [ ] Crear carpeta `docs/`
- [ ] Mover documentación a `docs/`
- [ ] Eliminar `docker/`, `scripts/`, `terraform/`
- [ ] Eliminar scripts legacy (`.sh` en raíz excepto `setup_odoo_complete.sh`)
- [ ] Eliminar `terraform.tfstate`
- [ ] Actualizar `.gitignore`
- [ ] Crear nuevo `README.md`
- [ ] Actualizar rutas en `INDICE-DOCUMENTACION.md`

### Post-limpieza

- [ ] Verificar estructura
  ```bash
  tree -L 2
  ```

- [ ] Probar deployment (en branch cleanup)
  ```bash
  cd deployments/on-demand/terraform
  terraform plan
  ```

- [ ] Commit y push
  ```bash
  git add -A
  git commit -m "Cleanup: Remove legacy files and reorganize documentation"
  git push origin cleanup/repo-structure
  ```

- [ ] Crear Pull Request
- [ ] Mergear a main si todo funciona

---

## 🎯 Ventajas de la Limpieza

### ✅ Claridad

- Estructura clara y simple
- Fácil encontrar archivos
- No hay duplicados

### ✅ Mantenibilidad

- Menos archivos = menos confusión
- Documentación organizada en `docs/`
- Deployments separados por tipo

### ✅ Seguridad

- `.gitignore` actualizado evita subir secrets
- No hay `terraform.tfstate` en Git

### ✅ Profesionalismo

- Repositorio limpio y organizado
- README claro en raíz
- Fácil onboarding para nuevos desarrolladores

---

## 🚀 Ejecutar Limpieza

### Opción A: Manual (Recomendado para primera vez)

```bash
# 1. Backup
cd ..
cp -r SERVER-SCRIPTS SERVER-SCRIPTS.backup
cd SERVER-SCRIPTS

# 2. Branch
git checkout -b cleanup/repo-structure

# 3. Crear docs/
mkdir docs

# 4. Mover documentación
mv README-COMPLETO.md docs/
mv GUIA-RAPIDA.md docs/
# ... (ver script arriba)

# 5. Eliminar legacy
rm -rf docker/ scripts/ terraform/
rm cleanup.sh deploy.sh # ... etc

# 6. Actualizar .gitignore
nano .gitignore

# 7. Commit
git add -A
git commit -m "Cleanup: Remove legacy files, reorganize docs"
git push origin cleanup/repo-structure
```

### Opción B: Script Automático

```bash
# Descargar y ejecutar script
chmod +x cleanup_repo.sh
./cleanup_repo.sh

# Revisar cambios
git status

# Commit
git add -A
git commit -m "Cleanup: Remove legacy files, reorganize docs"
git push origin cleanup/repo-structure
```

---

## ⚡ Siguiente Paso

¿Quieres que ejecute la limpieza?

**Opciones**:
1. ✅ **Sí, limpieza conservadora** (mantiene todo lo que podría ser útil)
2. ✅ **Sí, limpieza agresiva** (solo lo esencial)
3. ⏸️ **No ahora** (primero desarrollar Spot Instances)
4. 📝 **Primero revisar manualmente**

---

**Recomendación**: Ejecutar limpieza conservadora ANTES de desarrollar Spot Instances para tener base limpia.
