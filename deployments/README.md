# 📦 Deployments - Helipistas Odoo 17

Esta carpeta contiene **diferentes tipos de despliegue** para el proyecto Helipistas Odoo 17.

---

## 📁 Estructura

```
deployments/
├── README.md           ← Este archivo
├── on-demand/          ← Despliegue con EC2 On-Demand (PRODUCCIÓN)
│   ├── README.md
│   ├── setup_odoo_complete.sh
│   └── terraform/
│       ├── main-simple.tf
│       ├── user_data_simple.sh
│       └── ...
│
└── spot/               ← Despliegue con EC2 Spot Instances (DESARROLLO)
    ├── README.md       (próximamente)
    └── terraform/      (próximamente)
```

---

## 🎯 ¿Qué Tipo de Despliegue Usar?

### 🟢 On-Demand (Producción)

**📂 Carpeta**: `on-demand/`

**✅ Úsalo cuando**:
- Necesitas **disponibilidad garantizada 24/7**
- Es un entorno de **producción**
- No puedes tolerar interrupciones
- Necesitas una **IP fija** que nunca cambie
- El costo no es el factor principal

**💰 Costo**: ~$30-40/mes

**📊 Disponibilidad**: 100% (garantizada por AWS)

**🔗 Más info**: [`on-demand/README.md`](on-demand/README.md)

---

### 🟡 Spot Instances (Desarrollo/Staging)

**📂 Carpeta**: `spot/`

**✅ Úsalo cuando**:
- Es un entorno de **desarrollo o staging**
- Puedes tolerar **interrupciones ocasionales** (~5%)
- Quieres **ahorrar 70% de costos**
- No necesitas IP fija
- Tienes manejo automático de interrupciones

**💰 Costo**: ~$9-12/mes (70% descuento vs On-Demand)

**📊 Disponibilidad**: ~95% (puede interrumpirse con aviso de 2 minutos)

**🔗 Más info**: [`spot/README.md`](spot/README.md) *(próximamente)*

---

## 📊 Comparativa Detallada

| Característica | On-Demand | Spot |
|----------------|-----------|------|
| **Tipo** | Producción | Desarrollo/Staging |
| **Disponibilidad** | 100% garantizada | ~95% (interrupciones posibles) |
| **Costo mensual** | ~$30-40 | ~$9-12 (70% descuento) |
| **IP pública** | Fija (Elastic IP) | Cambia en cada nueva instancia |
| **DNS** | Siempre apunta a misma IP | Requiere actualización automática |
| **Complejidad** | Baja | Media (manejo de interrupciones) |
| **Setup inicial** | 10-12 minutos | 10-12 minutos |
| **Re-despliegue** | Manual (terraform destroy/apply) | Automático (si hay interrupción) |
| **Mantenimiento** | Bajo | Medio |
| **Ideal para** | Clientes finales | Desarrollo, pruebas |

---

## 🚀 Quick Start

### Despliegue On-Demand (Producción)

```bash
# 1. Ir a carpeta on-demand
cd deployments/on-demand/terraform

# 2. Configurar variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar con tus valores

# 3. Desplegar
terraform init
terraform apply
```

**Tiempo**: 10-12 minutos

**Resultado**: Odoo corriendo en https://erp17.helipistas.com

---

### Despliegue Spot (Desarrollo)

```bash
# 1. Ir a carpeta spot
cd deployments/spot/terraform

# 2. Configurar variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar con tus valores

# 3. Desplegar
terraform init
terraform apply
```

**Tiempo**: 10-12 minutos

**Resultado**: Odoo corriendo en IP dinámica (recibirás la IP en output)

---

## 🏗️ Arquitectura Común

Ambos despliegues comparten la misma arquitectura base:

```
Internet
   ↓
DNS (Route 53)
   ↓
IP Pública (Elastic IP en on-demand, dinámica en spot)
   ↓
EC2 Instance
   ├── Docker Compose
   │   ├── Nginx (proxy reverso + SSL)
   │   ├── Odoo 17
   │   └── PostgreSQL 15
   └── Montaje EFS
       └── /efs/HELIPISTAS-ODOO-17/
           ├── postgres/ (datos DB)
           ├── odoo/filestore/ (archivos)
           ├── odoo/conf/ (configuración)
           ├── nginx/ssl/ (certificados)
           └── certbot/conf/ (SSL)
```

**Diferencia clave**: El tipo de EC2 y cómo se gestiona su ciclo de vida.

---

## 🔄 Recursos Compartidos (No se eliminan)

Ambos tipos de despliegue **reutilizan** estos recursos AWS existentes:

- **EFS**: `fs-ec7152d9` (almacenamiento persistente)
- **VPC**: `vpc-92d074f6`
- **Subnet**: `subnet-c362e2a7`
- **Elastic IP** (solo on-demand): `eipalloc-0184418cc26d4e66f`

Hacer `terraform destroy` en cualquier deployment **NO** eliminará estos recursos.

**Los datos se mantienen seguros en EFS** y puedes redesplegar cuando quieras.

---

## 💡 Casos de Uso

### Escenario 1: Producción Estable

**Recomendación**: On-Demand

```bash
cd deployments/on-demand/terraform
terraform apply
```

**Por qué**:
- Disponibilidad 100%
- IP fija, DNS siempre funciona
- Clientes pueden acceder sin interrupciones

---

### Escenario 2: Desarrollo de Módulos Custom

**Recomendación**: Spot

```bash
cd deployments/spot/terraform
terraform apply
```

**Por qué**:
- Ahorro de 70%
- Si se interrumpe, se levanta automáticamente
- No afecta a usuarios finales

---

### Escenario 3: Staging/Pruebas

**Recomendación**: Spot

```bash
cd deployments/spot/terraform
terraform apply
```

**Por qué**:
- Ambiente casi idéntico a producción
- Costo muy bajo
- Ideal para pruebas de deployments

---

### Escenario 4: Demo para Cliente

**Recomendación**: On-Demand

```bash
cd deployments/on-demand/terraform
terraform apply
```

**Por qué**:
- No puede fallar durante la demo
- Acceso predecible
- URL fija y profesional

---

## 🔐 Seguridad

Ambos despliegues tienen:

- **Security Group** configurado (SSH, HTTP, HTTPS)
- **SSL/TLS** automático con Let's Encrypt
- **Secrets** en `terraform.tfvars` (NO en Git)
- **SSH** con clave PEM

**❌ NUNCA** subir a Git:
- `terraform.tfvars` (contiene contraseñas)
- Archivos `.pem` (claves SSH)

---

## 📚 Documentación

### Específica de Cada Deployment

- **On-Demand**: [`on-demand/README.md`](on-demand/README.md)
- **Spot**: [`spot/README.md`](spot/README.md) *(próximamente)*

### Documentación General del Proyecto

En la carpeta `docs/` del repositorio:

- **Índice maestro**: [`../docs/INDICE-DOCUMENTACION.md`](../docs/INDICE-DOCUMENTACION.md)
- **Guía rápida**: [`../docs/GUIA-RAPIDA.md`](../docs/GUIA-RAPIDA.md)
- **Documentación completa**: [`../docs/README-COMPLETO.md`](../docs/README-COMPLETO.md)
- **Guía desarrolladores**: [`../docs/GUIA-DESARROLLADORES.md`](../docs/GUIA-DESARROLLADORES.md)
- **Decisiones arquitectura**: [`../docs/DECISIONES-ARQUITECTURA.md`](../docs/DECISIONES-ARQUITECTURA.md)

---

## 🛠️ Gestión

### Ver Estado Actual

```bash
# On-Demand
cd deployments/on-demand/terraform
terraform show

# Spot
cd deployments/spot/terraform
terraform show
```

### Conectarse a la Instancia

```bash
# On-Demand (IP fija)
ssh -i /path/to/ERP.pem ec2-user@54.228.16.152

# Spot (IP dinámica, obtener de output)
cd deployments/spot/terraform
SPOT_IP=$(terraform output -raw instance_public_ip)
ssh -i /path/to/ERP.pem ec2-user@$SPOT_IP
```

### Destruir Infraestructura

```bash
# On-Demand
cd deployments/on-demand/terraform
terraform destroy

# Spot
cd deployments/spot/terraform
terraform destroy
```

**Nota**: Los datos en EFS (`fs-ec7152d9`) no se eliminan.

---

## 🔄 Migrar entre Tipos de Deployment

### De On-Demand a Spot

1. **Verificar datos en EFS**:
   ```bash
   ssh -i /path/to/ERP.pem ec2-user@<IP>
   ls -la /efs/HELIPISTAS-ODOO-17/
   ```

2. **Destruir On-Demand**:
   ```bash
   cd deployments/on-demand/terraform
   terraform destroy
   ```

3. **Desplegar Spot**:
   ```bash
   cd deployments/spot/terraform
   terraform apply
   ```

**Resultado**: Los datos se mantienen en EFS, solo cambia el tipo de EC2.

---

### De Spot a On-Demand

Mismo proceso inverso:

1. Verificar datos en EFS
2. Destruir Spot
3. Desplegar On-Demand

---

## 💰 Ahorro con Spot Instances

### Ejemplo Real (t3.medium en eu-west-1)

| Concepto | On-Demand | Spot | Ahorro |
|----------|-----------|------|--------|
| **Por hora** | $0.0416 | $0.0125 | $0.0291 (70%) |
| **Por día** | $0.9984 | $0.30 | $0.6984 |
| **Por mes** | $30.37 | $9.11 | $21.26 (70%) |
| **Por año** | $364.42 | $109.33 | $255.09 (70%) |

**Ahorro anual con Spot**: ~$255 💰

**Nota**: Precios aproximados, pueden variar según disponibilidad.

---

## 🆚 ¿Cuándo NO Usar Spot?

❌ **No usar Spot si**:
- Es tu único entorno de producción
- Clientes acceden directamente 24/7
- No puedes tolerar interrupciones de 2 minutos
- Necesitas compliance estricto de uptime
- No tienes manejo automático de interrupciones

✅ **Sí usar On-Demand en estos casos**

---

## 📞 Soporte

Para más información:

- **Documentación principal**: [`../docs/INDICE-DOCUMENTACION.md`](../docs/INDICE-DOCUMENTACION.md)
- **Issues GitHub**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/issues

---

**🎯 Elige el deployment que mejor se adapte a tus necesidades de disponibilidad y presupuesto.**

- **Producción crítica** → On-Demand (`on-demand/`)
- **Desarrollo/Staging** → Spot (`spot/`)
