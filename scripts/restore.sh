#!/bin/bash

# Script de restauración de backup para Odoo
# Se ejecuta en el servidor remoto

set -e

# Configuración
BACKUP_DIR="/opt/odoo/backup"
LOG_FILE="/var/log/odoo-restore.log"

# Función de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

error() {
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
    exit 1
}

warn() {
    echo "[WARNING $(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Mostrar ayuda
show_help() {
    echo "Script de restauración de backup de Odoo"
    echo ""
    echo "Uso: $0 <backup_file> [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --db-only          Restaurar solo la base de datos"
    echo "  --data-only        Restaurar solo los datos de Odoo"
    echo "  --config-only      Restaurar solo la configuración"
    echo "  --force            No pedir confirmación"
    echo ""
    echo "Ejemplos:"
    echo "  $0 complete_backup_20231201_120000.tar.gz"
    echo "  $0 odoo_db_20231201_120000.sql.gz --db-only"
    echo "  $0 complete_backup_20231201_120000.tar.gz --force"
}

# Verificar argumentos
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

BACKUP_FILE="$1"
DB_ONLY=false
DATA_ONLY=false
CONFIG_ONLY=false
FORCE=false

# Procesar argumentos
shift
while [[ $# -gt 0 ]]; do
    case $1 in
        --db-only)
            DB_ONLY=true
            shift
            ;;
        --data-only)
            DATA_ONLY=true
            shift
            ;;
        --config-only)
            CONFIG_ONLY=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            error "Opción desconocida: $1"
            ;;
    esac
done

# Verificar que el archivo de backup existe
if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ] && [ ! -f "$BACKUP_FILE" ]; then
    error "Archivo de backup no encontrado: $BACKUP_FILE"
fi

# Usar ruta completa
if [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"
else
    BACKUP_PATH="$BACKUP_FILE"
fi

log "Iniciando restauración desde: $BACKUP_PATH"

# Advertencia de seguridad
if [ "$FORCE" = false ]; then
    echo "⚠️  ADVERTENCIA: Esta operación sobrescribirá los datos actuales de Odoo"
    echo "   Archivo de backup: $BACKUP_PATH"
    echo "   Fecha actual: $(date)"
    echo ""
    read -p "¿Continuar con la restauración? (escribe 'yes' para confirmar): " confirm
    
    if [ "$confirm" != "yes" ]; then
        log "Restauración cancelada por el usuario"
        exit 0
    fi
fi

# Crear directorio temporal
TEMP_DIR="/tmp/odoo_restore_$(date +%s)"
mkdir -p $TEMP_DIR

# Función de limpieza
cleanup() {
    log "Limpiando archivos temporales..."
    rm -rf $TEMP_DIR
}
trap cleanup EXIT

# Detectar tipo de backup
if [[ "$BACKUP_FILE" == *"complete_backup"* ]]; then
    BACKUP_TYPE="complete"
elif [[ "$BACKUP_FILE" == *"odoo_db"* ]]; then
    BACKUP_TYPE="database"
elif [[ "$BACKUP_FILE" == *"odoo_data"* ]]; then
    BACKUP_TYPE="data"
elif [[ "$BACKUP_FILE" == *"nginx_config"* ]]; then
    BACKUP_TYPE="config"
else
    warn "Tipo de backup no detectado, asumiendo backup completo"
    BACKUP_TYPE="complete"
fi

log "Tipo de backup detectado: $BACKUP_TYPE"

# Extraer backup si es necesario
if [[ "$BACKUP_PATH" == *.tar.gz ]]; then
    log "Extrayendo backup..."
    cd $TEMP_DIR
    tar -xzf "$BACKUP_PATH"
    
    if [ $? -ne 0 ]; then
        error "Error extrayendo el backup"
    fi
fi

# Detener servicios
log "Deteniendo servicios de Odoo..."
cd /opt/odoo
docker-compose stop odoo nginx

# Restaurar base de datos
restore_database() {
    log "Restaurando base de datos PostgreSQL..."
    
    # Encontrar archivo de base de datos
    if [ "$BACKUP_TYPE" = "complete" ]; then
        DB_FILE=$(find $TEMP_DIR -name "*odoo_db*.sql.gz" | head -1)
    else
        if [[ "$BACKUP_PATH" == *.sql.gz ]]; then
            DB_FILE="$BACKUP_PATH"
        else
            DB_FILE=$(find $TEMP_DIR -name "*.sql.gz" | head -1)
        fi
    fi
    
    if [ -z "$DB_FILE" ]; then
        error "Archivo de base de datos no encontrado"
    fi
    
    log "Usando archivo de BD: $DB_FILE"
    
    # Eliminar base de datos existente
    docker exec odoo_postgresql dropdb -U odoo odoo 2>/dev/null || true
    
    # Crear nueva base de datos
    docker exec odoo_postgresql createdb -U odoo odoo
    
    # Restaurar datos
    zcat "$DB_FILE" | docker exec -i odoo_postgresql psql -U odoo -d odoo
    
    if [ $? -eq 0 ]; then
        log "✓ Base de datos restaurada correctamente"
    else
        error "✗ Error restaurando la base de datos"
    fi
}

# Restaurar datos de Odoo
restore_data() {
    log "Restaurando datos de Odoo..."
    
    # Encontrar archivo de datos
    if [ "$BACKUP_TYPE" = "complete" ]; then
        DATA_FILE=$(find $TEMP_DIR -name "*odoo_data*.tar.gz" | head -1)
    else
        if [[ "$BACKUP_PATH" == *odoo_data*.tar.gz ]]; then
            DATA_FILE="$BACKUP_PATH"
        else
            DATA_FILE=$(find $TEMP_DIR -name "*odoo_data*.tar.gz" | head -1)
        fi
    fi
    
    if [ -z "$DATA_FILE" ]; then
        error "Archivo de datos no encontrado"
    fi
    
    log "Usando archivo de datos: $DATA_FILE"
    
    # Hacer backup de datos actuales
    if [ -d "/opt/odoo/data" ]; then
        log "Respaldando datos actuales..."
        mv /opt/odoo/data /opt/odoo/data.backup.$(date +%s)
    fi
    
    # Restaurar datos
    cd /opt/odoo
    tar -xzf "$DATA_FILE"
    
    if [ $? -eq 0 ]; then
        log "✓ Datos de Odoo restaurados correctamente"
    else
        error "✗ Error restaurando datos de Odoo"
    fi
    
    # Ajustar permisos
    chown -R ec2-user:ec2-user /opt/odoo/data
}

# Restaurar configuración
restore_config() {
    log "Restaurando configuración..."
    
    # Encontrar archivo de configuración
    if [ "$BACKUP_TYPE" = "complete" ]; then
        CONFIG_FILE=$(find $TEMP_DIR -name "*nginx_config*.tar.gz" | head -1)
    else
        if [[ "$BACKUP_PATH" == *nginx_config*.tar.gz ]]; then
            CONFIG_FILE="$BACKUP_PATH"
        else
            CONFIG_FILE=$(find $TEMP_DIR -name "*nginx_config*.tar.gz" | head -1)
        fi
    fi
    
    if [ -z "$CONFIG_FILE" ]; then
        warn "Archivo de configuración no encontrado, saltando..."
        return
    fi
    
    log "Usando archivo de configuración: $CONFIG_FILE"
    
    # Hacer backup de configuración actual
    if [ -d "/opt/odoo/nginx" ]; then
        log "Respaldando configuración actual..."
        mv /opt/odoo/nginx /opt/odoo/nginx.backup.$(date +%s)
    fi
    
    # Restaurar configuración
    cd /opt/odoo
    tar -xzf "$CONFIG_FILE"
    
    if [ $? -eq 0 ]; then
        log "✓ Configuración restaurada correctamente"
    else
        error "✗ Error restaurando configuración"
    fi
    
    # Ajustar permisos
    chown -R ec2-user:ec2-user /opt/odoo/nginx
}

# Ejecutar restauración según las opciones
if [ "$DB_ONLY" = true ]; then
    restore_database
elif [ "$DATA_ONLY" = true ]; then
    restore_data
elif [ "$CONFIG_ONLY" = true ]; then
    restore_config
else
    # Restauración completa
    restore_database
    restore_data
    restore_config
fi

# Reiniciar servicios
log "Reiniciando servicios..."
cd /opt/odoo
docker-compose up -d

# Esperar a que los servicios estén listos
log "Esperando a que los servicios estén disponibles..."
sleep 30

# Verificar que Odoo esté funcionando
for i in {1..12}; do
    if curl -s --connect-timeout 5 http://localhost/health > /dev/null; then
        log "✓ Odoo está funcionando correctamente"
        break
    else
        if [ $i -eq 12 ]; then
            warn "Odoo no responde, verifica los logs"
        else
            log "Esperando a que Odoo esté disponible... (intento $i/12)"
            sleep 10
        fi
    fi
done

log "Restauración completada"
log "Verifica que todo funcione correctamente:"
log "  - docker-compose ps"
log "  - docker-compose logs odoo"
log "  - curl http://localhost/health"
