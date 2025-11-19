# 🚀 Helipistas ERP - Odoo 17 en AWS

Deployment automatizado de Odoo 17 en AWS usando Terraform con persistencia en EFS y SSL automático.

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.0-623CE4?logo=terraform)](https://www.terraform.io/)
[![AWS](https://img.shields.io/badge/AWS-EC2%20%7C%20EFS-FF9900?logo=amazon-aws)](https://aws.amazon.com/)
[![Odoo](https://img.shields.io/badge/Odoo-17-714B67?logo=odoo)](https://www.odoo.com/)

---

## 📦 Tipos de Despliegue

Este proyecto soporta **dos tipos de despliegue** optimizados para diferentes casos de uso:

### 🟢 On-Demand (Producción)

**Carpeta**: [`deployments/on-demand/`](deployments/on-demand/)

✅ **Disponibilidad**: 100% garantizada  
✅ **IP**: Fija (Elastic IP)  
✅ **Ideal para**: Producción, clientes finales  
💰 **Costo**: ~$30-40/mes  

[📖 Ver documentación completa](deployments/on-demand/README.md)

### 🟡 Spot Instances (Desarrollo/Staging)

**Carpeta**: [`deployments/spot/`](deployments/spot/)

✅ **Ahorro**: 70% vs On-Demand  
✅ **IP**: Dinámica  
✅ **Ideal para**: Desarrollo, staging, pruebas  
💰 **Costo**: ~$9-12/mes  

[📖 Ver documentación](deployments/spot/README.md) *(próximamente)*

---

### 📊 Comparativa Rápida

| Característica | On-Demand | Spot |
|----------------|-----------|------|
| **Disponibilidad** | 100% | ~95% |
| **Costo mensual** | $30-40 | $9-12 |
| **IP pública** | Fija | Dinámica |
| **Ideal para** | Producción | Dev/Staging |

**Ver comparativa completa**: [`deployments/README.md`](deployments/README.md)

---

## 🚀 Quick Start

### Despliegue On-Demand (Producción)

```bash
# 1. Clonar repositorio
git clone https://github.com/leulit/helipistas-erp-odoo-17-server-scripts.git
cd helipistas-erp-odoo-17-server-scripts

# 2. Configurar credenciales AWS
aws configure

# 3. Ir a carpeta de deployment
cd deployments/on-demand/terraform

# 4. Copiar y configurar variables
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Editar con tus valores

# 5. Desplegar
terraform init
terraform apply
```

**Tiempo**: 10-12 minutos

**Resultado**: Odoo 17 corriendo en https://tu-dominio.com

---

## ✨ Características Principales

- ✅ **Deployment 100% Automatizado** - Un comando despliega todo
- ✅ **Persistencia con EFS** - Datos seguros incluso si la EC2 se destruye
- ✅ **SSL/HTTPS Automático** - Let's Encrypt con renovación automática
- ✅ **Arquitectura Docker** - PostgreSQL 15 + Odoo 17 + Nginx
- ✅ **IP Estática** - Elastic IP reutilizable (on-demand)
- ✅ **Infraestructura como Código** - Reproducible en cualquier momento
- ✅ **Multi-ambiente** - Desarrollo, staging y producción

---

## 🏗️ Arquitectura

```
Internet → Route 53 → Elastic IP → EC2 Instance
                                    ├── Docker: Nginx (Proxy + SSL)
                                    ├── Docker: Odoo 17
                                    └── Docker: PostgreSQL 15
                                         └── Datos en EFS (Persistente)
```

**Diagrama completo**: Ver [`docs/README-COMPLETO.md`](docs/README-COMPLETO.md#arquitectura-del-sistema)

---

## 📚 Documentación

### 🎯 ¿Qué documento leer?

Empieza aquí: **[`docs/INDICE-DOCUMENTACION.md`](docs/INDICE-DOCUMENTACION.md)**

Te guiará al documento correcto según tu rol (nuevo, admin, desarrollador, arquitecto).

### 📖 Documentación Principal

| Documento | Descripción | Tiempo lectura |
|-----------|-------------|----------------|
| **[Índice](docs/INDICE-DOCUMENTACION.md)** | ¿Qué documento leer? | 5 min |
| **[Resumen Ejecutivo](docs/RESUMEN-EJECUTIVO.md)** | Visión general del proyecto | 15 min |
| **[Guía Rápida](docs/GUIA-RAPIDA.md)** | Comandos del día a día | 20 min |
| **[README Completo](docs/README-COMPLETO.md)** | Documentación técnica completa | 1-2 horas |
| **[Guía Desarrolladores](docs/GUIA-DESARROLLADORES.md)** | Modificar el proyecto | 1-2 horas |
| **[Decisiones Arquitectura](docs/DECISIONES-ARQUITECTURA.md)** | Por qué se decidió X | 30-60 min |

### 📁 Documentación por Tipo de Deployment

- **On-Demand**: [`deployments/on-demand/README.md`](deployments/on-demand/README.md)
- **Spot**: [`deployments/spot/README.md`](deployments/spot/README.md)
- **Comparativa**: [`deployments/README.md`](deployments/README.md)

---

## 🔧 Requisitos Previos

- **Terraform** >= 1.0
- **AWS CLI** configurado con credenciales
- **Cuenta AWS** con permisos para EC2, EFS, VPC
- **Dominio** apuntando a la IP de AWS (para SSL)
- **Clave SSH** (.pem) para acceder a EC2

---

## 📋 Gestión Diaria

### Conectarse a la Instancia

```bash
ssh -i /path/to/tu-clave.pem ec2-user@<IP-DE-TU-INSTANCIA>
```

### Ver Logs

```bash
# En la instancia EC2
docker-compose logs -f          # Todos los servicios
docker-compose logs -f odoo     # Solo Odoo
docker-compose logs -f nginx    # Solo Nginx
```

### Reiniciar Servicios

```bash
# En la instancia EC2
cd /efs/HELIPISTAS-ODOO-17
docker-compose restart          # Todos
docker-compose restart odoo     # Solo Odoo
```

**Guía completa**: [`docs/GUIA-RAPIDA.md`](docs/GUIA-RAPIDA.md)

---

## 🔐 Seguridad

- ✅ **SSL/TLS** con Let's Encrypt (renovación automática)
- ✅ **Security Group** configurado (SSH, HTTP, HTTPS)
- ✅ **Secrets** en `terraform.tfvars` (NO en Git)
- ✅ **Datos encriptados** en EFS (opcional)

**Más información**: [`docs/README-COMPLETO.md`](docs/README-COMPLETO.md#seguridad-y-ssl)

---

## 🐛 Troubleshooting

### Odoo no arranca

```bash
# Ver logs
docker-compose logs odoo

# Reiniciar
docker-compose restart odoo
```

### SSL no funciona

```bash
# Verificar certificados
docker-compose logs certbot

# Renovar manualmente
docker-compose run certbot renew
```

**Guía completa de troubleshooting**: [`docs/README-COMPLETO.md`](docs/README-COMPLETO.md#troubleshooting)

---

## 🗂️ Estructura del Proyecto

```
helipistas-erp-odoo-17-server-scripts/
├── README.md                    ← Este archivo
├── LICENSE                      ← Licencia MIT
├── setup_odoo_complete.sh       ← Script descargado por EC2 (CRÍTICO)
│
├── deployments/                 ← Tipos de deployment
│   ├── README.md                ← Comparativa de tipos
│   ├── on-demand/               ← Producción (EC2 On-Demand)
│   │   ├── README.md
│   │   ├── setup_odoo_complete.sh
│   │   └── terraform/
│   │       ├── main-simple.tf
│   │       ├── user_data_simple.sh
│   │       └── ...
│   └── spot/                    ← Desarrollo (EC2 Spot)
│       └── README.md
│
└── docs/                        ← Documentación completa
    ├── INDICE-DOCUMENTACION.md  ← Empieza aquí
    ├── RESUMEN-EJECUTIVO.md
    ├── GUIA-RAPIDA.md
    ├── README-COMPLETO.md
    ├── GUIA-DESARROLLADORES.md
    └── DECISIONES-ARQUITECTURA.md
```

---

## 💰 Costos Estimados

### Producción (On-Demand)

- **EC2 t3.medium**: ~$30/mes
- **EFS**: ~$0.30/GB/mes (según uso)
- **Elastic IP**: Gratis (mientras esté asociada)
- **Total**: ~$35-45/mes

### Desarrollo (Spot)

- **EC2 t3.medium Spot**: ~$9/mes (70% descuento)
- **EFS**: ~$0.30/GB/mes
- **Total**: ~$10-15/mes

**Ahorro anual con Spot**: ~$255/año en ambiente de desarrollo

---

## 🤝 Contribuir

Las contribuciones son bienvenidas!

1. Fork el proyecto
2. Crea un branch (`git checkout -b feature/amazing-feature`)
3. Commit tus cambios (`git commit -m 'Add amazing feature'`)
4. Push al branch (`git push origin feature/amazing-feature`)
5. Abre un Pull Request

---

## 📞 Soporte

- **Documentación**: [`docs/INDICE-DOCUMENTACION.md`](docs/INDICE-DOCUMENTACION.md)
- **Issues**: [GitHub Issues](https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/issues)
- **Email**: [Crear issue en GitHub](https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/issues/new)

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver [`LICENSE`](LICENSE) para más detalles.

---

## 🌟 Casos de Uso

- ✅ **ERP para PYMEs** en AWS con infraestructura predecible
- ✅ **Desarrollo y testing** con costos reducidos (Spot)
- ✅ **Múltiples ambientes** (dev, staging, prod) con misma configuración
- ✅ **Disaster recovery** con capacidad de recrear infraestructura rápidamente
- ✅ **Prototipado rápido** de soluciones ERP

---

## 🚦 Estado del Proyecto

- ✅ **On-Demand Deployment**: Producción, probado, documentado
- 🚧 **Spot Instances Deployment**: En desarrollo
- 📝 **Documentación**: Completa (6 documentos, ~5000 líneas)

---

## 🎯 Próximos Pasos

1. ✅ **Lee la documentación**: Empieza con [`docs/INDICE-DOCUMENTACION.md`](docs/INDICE-DOCUMENTACION.md)
2. ✅ **Elige tu tipo de deployment**: [`deployments/README.md`](deployments/README.md)
3. ✅ **Despliega**: Sigue la guía del deployment elegido
4. ✅ **Gestiona**: Usa [`docs/GUIA-RAPIDA.md`](docs/GUIA-RAPIDA.md) para operaciones diarias

---

**¡Bienvenido al proyecto Helipistas Odoo 17!** 🎉

Si tienes dudas, consulta la documentación o crea un issue en GitHub.
