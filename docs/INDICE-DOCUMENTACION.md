# 📚 Índice de Documentación - Helipistas Odoo 17

## 🎯 ¿Qué documento debo leer?

### 🚀 **Si eres NUEVO en el proyecto** (15-20 min)
**Lee primero**: [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md)

Contiene:
- Visión general del proyecto en 30 segundos
- Arquitectura simplificada
- Comandos esenciales (quick start)
- Checklist para nuevos desarrolladores

---

### 👨‍💼 **Si eres ADMINISTRADOR del sistema** (1 hora)
**Lee en este orden**:

1. [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) - 15 min
2. [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) - 20 min
3. Secciones relevantes de [`README-COMPLETO.md`](README-COMPLETO.md) - 30 min

**Documentos clave para tu rol**:
- **Día a día**: [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md)
- **Troubleshooting**: [`README-COMPLETO.md`](README-COMPLETO.md) → Sección "Troubleshooting"
- **Comandos Docker**: [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) → "Gestión de Servicios"

---

### 👨‍💻 **Si eres DESARROLLADOR** (2-3 horas)
**Lee en este orden**:

1. [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) - 15 min
2. [`README-COMPLETO.md`](README-COMPLETO.md) - 1 hora
3. [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) - 1 hora
4. [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) - 30 min

**Documentos clave para tu rol**:
- **Arquitectura técnica**: [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) → "Arquitectura Técnica"
- **Modificar proyecto**: [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) → "Modificar Configuraciones"
- **Por qué se decidió X**: [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md)
- **Debugging**: [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) → "Debugging y Logs"

---

### 🏛️ **Si eres ARQUITECTO o necesitas entender decisiones** (1 hora)
**Lee en este orden**:

1. [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) - 15 min
2. [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) - 45 min

**Documentos clave para tu rol**:
- **ADR (Architecture Decision Records)**: [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md)
- **Trade-offs**: [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) → "Resumen de Trade-offs"
- **Arquitectura detallada**: [`README-COMPLETO.md`](README-COMPLETO.md) → "Arquitectura del Sistema"

---

## 📂 Documentos Disponibles

### 1. [`README-COMPLETO.md`](README-COMPLETO.md) 📖
**Documentación técnica exhaustiva del proyecto**

**Audiencia**: Todos (referencia completa)

**Contenido**:
- ✅ Descripción general del proyecto
- ✅ Diagrama completo de arquitectura
- ✅ Estructura del proyecto (archivos y directorios)
- ✅ Requisitos previos (herramientas, cuentas AWS, recursos)
- ✅ Configuración inicial paso a paso
- ✅ Proceso de deployment completo
- ✅ Flujo de deployment automático detallado
- ✅ Gestión y mantenimiento
- ✅ Arquitectura de datos en EFS
- ✅ Seguridad y SSL
- ✅ Troubleshooting exhaustivo
- ✅ Referencias técnicas y comandos

**Cuándo leerlo**:
- Primera vez que trabajas con el proyecto
- Necesitas entender algún componente en profundidad
- Troubleshooting de problemas complejos
- Referencia de comandos y configuraciones

---

### 2. [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) ⚡
**Comandos del día a día y solución rápida de problemas**

**Audiencia**: Administradores, DevOps

**Contenido**:
- ✅ Comandos más usados (desplegar, conectarse, ver logs)
- ✅ Gestión de servicios Docker
- ✅ Verificación de SSL
- ✅ Monitoreo de logs
- ✅ Backup manual
- ✅ Acceso a PostgreSQL y Odoo
- ✅ Solución rápida de problemas comunes
- ✅ URLs de acceso y credenciales
- ✅ Ubicaciones importantes

**Cuándo leerlo**:
- Operaciones diarias del sistema
- Necesitas un comando específico rápidamente
- Troubleshooting básico

---

### 3. [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) 🔧
**Guía técnica para desarrolladores que necesitan modificar el proyecto**

**Audiencia**: Desarrolladores, DevOps avanzado

**Contenido**:
- ✅ Arquitectura técnica detallada (stack completo)
- ✅ Flujo de deployment con timing
- ✅ Cómo modificar configuraciones (Odoo, Nginx, PostgreSQL)
- ✅ Cómo agregar funcionalidades (contenedores, módulos)
- ✅ Debugging avanzado con logs multi-nivel
- ✅ Testing de deployments
- ✅ Best practices (seguridad, mantenimiento, desarrollo)
- ✅ Referencias a documentación oficial

**Cuándo leerlo**:
- Necesitas modificar configuración de Odoo o Nginx
- Quieres agregar un nuevo contenedor Docker
- Debugging de problemas complejos
- Antes de hacer cambios significativos al proyecto

---

### 4. [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) 📊
**Visión general rápida del proyecto (ideal para nuevos)**

**Audiencia**: Todos (especialmente nuevos al proyecto)

**Contenido**:
- ✅ Qué es el proyecto (descripción en 30 seg)
- ✅ Arquitectura simplificada
- ✅ Quick start (desplegar, conectarse, ver servicios)
- ✅ Archivos clave y cuándo modificarlos
- ✅ Recursos AWS que se reutilizan
- ✅ Flujo de deployment simplificado
- ✅ Comandos más usados
- ✅ Troubleshooting rápido
- ✅ Casos de uso comunes
- ✅ Checklist para nuevos desarrolladores

**Cuándo leerlo**:
- Primera vez que ves el proyecto (START HERE)
- Necesitas una visión general rápida
- Quieres entender el proyecto en 15-20 minutos

---

### 5. [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) 🏛️
**Registro de decisiones de arquitectura (ADR)**

**Audiencia**: Arquitectos, Tech Leads, Desarrolladores senior

**Contenido**:
- ✅ Por qué usar Terraform en lugar de scripts
- ✅ Por qué reutilizar recursos AWS existentes
- ✅ Por qué dividir user_data en dos scripts
- ✅ Por qué usar Docker Compose
- ✅ Por qué montar EFS en /efs
- ✅ Por qué usar Let's Encrypt
- ✅ Por qué Nginx como proxy reverso
- ✅ Por qué proxy_mode=True en Odoo
- ✅ Por qué 2 workers de Odoo
- ✅ Por qué EC2 On-Demand vs Spot
- ✅ Por qué timestamp fuerza recreación
- ✅ Por qué flags de certbot
- ✅ Resumen de trade-offs
- ✅ Decisiones futuras a considerar

**Cuándo leerlo**:
- Necesitas entender por qué se tomó una decisión técnica
- Planeas hacer cambios arquitectónicos significativos
- Documentar nuevas decisiones
- Evaluar alternativas técnicas

---

## 🗺️ Rutas de Aprendizaje

### 📍 Ruta 1: "Quiero usar el sistema YA" (30 min)

1. Leer [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) - 15 min
2. Leer sección "Quick Start" de [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) - 5 min
3. Ejecutar deployment - 10 min
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```

---

### 📍 Ruta 2: "Soy administrador del sistema" (1-2 horas)

1. [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) - 15 min
2. [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) completo - 30 min
3. [`README-COMPLETO.md`](README-COMPLETO.md) → Secciones:
   - Arquitectura del Sistema - 15 min
   - Gestión y Mantenimiento - 20 min
   - Troubleshooting - 15 min

---

### 📍 Ruta 3: "Soy desarrollador y debo modificar el proyecto" (2-3 horas)

1. [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) - 15 min
2. [`README-COMPLETO.md`](README-COMPLETO.md) - 1 hora
   - Leer completo, enfocarse en:
   - Arquitectura
   - Estructura del Proyecto
   - Flujo de Deployment
3. [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) - 1 hora
   - Enfocarse en:
   - Arquitectura Técnica
   - Modificar Configuraciones
   - Agregar Funcionalidades
4. [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) - 30 min
   - Entender decisiones clave
   - Consultar según necesidad

---

### 📍 Ruta 4: "Necesito entender decisiones arquitectónicas" (1 hora)

1. [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) - 15 min
2. [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) - 45 min
   - Leer completo
   - Enfocarse en decisiones relevantes a tu pregunta

---

## 🔍 Buscar Información Específica

### "¿Cómo despliego la infraestructura?"

👉 [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) → Quick Start
👉 [`README-COMPLETO.md`](README-COMPLETO.md) → Despliegue de Infraestructura

---

### "¿Cómo veo los logs?"

👉 [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) → Ver Logs en Tiempo Real
👉 [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) → Debugging y Logs

---

### "¿Cómo modifico la configuración de Odoo?"

👉 [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) → Modificar Configuraciones → Cambiar Configuración de Odoo

---

### "¿Cómo funciona el SSL automático?"

👉 [`README-COMPLETO.md`](README-COMPLETO.md) → Seguridad y SSL
👉 [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) → Decisión #6

---

### "¿Por qué se usa Docker Compose?"

👉 [`DECISIONES-ARQUITECTURA.md`](DECISIONES-ARQUITECTURA.md) → Decisión #4

---

### "¿Dónde están los datos?"

👉 [`README-COMPLETO.md`](README-COMPLETO.md) → Arquitectura de Datos
👉 [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) → Datos Persistentes

---

### "Odoo no arranca, ¿qué hago?"

👉 [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) → Solución Rápida de Problemas
👉 [`README-COMPLETO.md`](README-COMPLETO.md) → Troubleshooting → Odoo no arranca
👉 [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) → Debugging → Odoo no arranca

---

### "¿Cómo agrego un módulo custom a Odoo?"

👉 [`GUIA-DESARROLLADORES.md`](GUIA-DESARROLLADORES.md) → Agregar Funcionalidades → Agregar Módulo Custom
👉 [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) → Casos de Uso → Instalar módulo custom

---

### "¿Qué comandos de Docker Compose puedo usar?"

👉 [`GUIA-RAPIDA.md`](GUIA-RAPIDA.md) → Comandos Más Usados → Gestión de Servicios
👉 [`README-COMPLETO.md`](README-COMPLETO.md) → Referencias Técnicas → Docker Compose

---

## 📊 Comparativa de Documentos

| Documento | Extensión | Tiempo Lectura | Nivel Técnico | Propósito |
|-----------|-----------|----------------|---------------|-----------|
| **RESUMEN-EJECUTIVO** | Corto | 15-20 min | Básico | Introducción rápida |
| **GUIA-RAPIDA** | Medio | 20-30 min | Básico-Medio | Operaciones diarias |
| **README-COMPLETO** | Largo | 1-2 horas | Medio-Alto | Referencia completa |
| **GUIA-DESARROLLADORES** | Largo | 1-2 horas | Alto | Desarrollo y modificación |
| **DECISIONES-ARQUITECTURA** | Medio | 30-60 min | Alto | Contexto de decisiones |

---

## 🎯 Matriz de Audiencia vs. Documentos

| Audiencia | Lectura Esencial | Lectura Recomendada | Lectura Opcional |
|-----------|------------------|---------------------|------------------|
| **Nuevo al proyecto** | RESUMEN-EJECUTIVO | README-COMPLETO | GUIA-DESARROLLADORES |
| **Administrador** | GUIA-RAPIDA | README-COMPLETO → Troubleshooting | DECISIONES-ARQUITECTURA |
| **DevOps** | GUIA-RAPIDA | README-COMPLETO | GUIA-DESARROLLADORES |
| **Desarrollador** | GUIA-DESARROLLADORES | README-COMPLETO, DECISIONES-ARQUITECTURA | GUIA-RAPIDA |
| **Arquitecto** | DECISIONES-ARQUITECTURA | README-COMPLETO → Arquitectura | GUIA-DESARROLLADORES |
| **Tech Lead** | Todos | - | - |

---

## 📝 Contribuir a la Documentación

Si encuentras algo que falta o está desactualizado:

1. **Crear issue en GitHub**:
   - Describir qué falta o está mal
   - Sugerir mejora

2. **Hacer PR con cambios**:
   - Editar documento relevante
   - Seguir formato existente
   - Actualizar este índice si agregaste nuevo documento

3. **Guidelines**:
   - Usar Markdown estándar
   - Mantener TOC (tabla de contenidos) actualizada
   - Agregar ejemplos cuando sea posible
   - Ser conciso pero completo

---

## 📦 Tipos de Despliegue

El proyecto soporta **dos tipos de despliegue**:

### 🟢 On-Demand (Producción)

- **Carpeta**: [`deployments/on-demand/`](deployments/on-demand/)
- **Documentación**: [`deployments/on-demand/README.md`](deployments/on-demand/README.md)
- **Características**:
  - Disponibilidad 100% garantizada
  - IP fija (Elastic IP)
  - Ideal para producción
  - Costo: ~$30-40/mes

### 🟡 Spot Instances (Desarrollo/Staging)

- **Carpeta**: [`deployments/spot/`](deployments/spot/)
- **Documentación**: [`deployments/spot/README.md`](deployments/spot/README.md) *(próximamente)*
- **Características**:
  - Ahorro 70% vs On-Demand
  - IP dinámica
  - Ideal para desarrollo
  - Costo: ~$9-12/mes

**Comparativa completa**: [`deployments/README.md`](deployments/README.md)

---

## 🔗 Enlaces Útiles

- **Repositorio GitHub**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts
- **Issues**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/issues
- **Pull Requests**: https://github.com/leulit/helipistas-erp-odoo-17-server-scripts/pulls

### Documentación de Deployments

- **Índice de tipos de deployment**: [`deployments/README.md`](deployments/README.md)
- **Deployment On-Demand**: [`deployments/on-demand/README.md`](deployments/on-demand/README.md)
- **Deployment Spot**: [`deployments/spot/README.md`](deployments/spot/README.md) *(próximamente)*

---

**¡Bienvenido al proyecto Helipistas Odoo 17! Este índice te ayudará a encontrar la documentación que necesitas rápidamente.** 📚

Si tienes dudas sobre qué documento leer, empieza con [`RESUMEN-EJECUTIVO.md`](RESUMEN-EJECUTIVO.md) ✨
