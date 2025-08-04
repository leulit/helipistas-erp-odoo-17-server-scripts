#!/bin/bash

# Script de backup avanzado para Odoo
# Se ejecuta en el servidor remoto

set -e

# Configuración - Usar estructura del proyecto
BACKUP_DIR="/efs/HLP-ERP-ODOO-17/POSTGRESQL/backups"
PROJECT_DIR="/efs/HLP-ERP-ODOO-17"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7
LOG_FILE="/efs/HLP-ERP-ODOO-17/POSTGRESQL/logs/backup.log"

# Configuración S3 (opcional)
S3_BUCKET="${S3_BACKUP_BUCKET:-}"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Función de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

error() {
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
    exit 1
}

# Crear directorio de backup
mkdir -p $BACKUP_DIR

log "Iniciando backup de Odoo - $DATE"

# Verificar que PostgreSQL esté funcionando
if ! docker exec odoo_postgresql pg_isready -U odoo > /dev/null 2>&1; then
    error "PostgreSQL no está disponible"
fi

# Backup de base de datos PostgreSQL
log "Creando backup de PostgreSQL..."
docker exec odoo_postgresql pg_dump -U odoo -h localhost odoo | gzip > $BACKUP_DIR/odoo_db_$DATE.sql.gz

if [ $? -eq 0 ]; then
    log "Backup de PostgreSQL completado: odoo_db_$DATE.sql.gz"
else
    error "Error en backup de PostgreSQL"
fi

# Backup de datos de Odoo (filestore)
log "Creando backup de datos de Odoo..."
tar -czf $BACKUP_DIR/odoo_data_$DATE.tar.gz -C /opt/odoo data addons config

if [ $? -eq 0 ]; then
    log "Backup de datos de Odoo completado: odoo_data_$DATE.tar.gz"
else
    error "Error en backup de datos de Odoo"
fi

# Backup de configuración de nginx
log "Creando backup de configuración nginx..."
tar -czf $BACKUP_DIR/nginx_config_$DATE.tar.gz -C /opt/odoo nginx/conf nginx/ssl

if [ $? -eq 0 ]; then
    log "Backup de nginx completado: nginx_config_$DATE.tar.gz"
else
    log "Warning: Error en backup de nginx (puede ser normal si no hay SSL)"
fi

# Crear backup completo
log "Creando backup completo..."
tar -czf $BACKUP_DIR/complete_backup_$DATE.tar.gz -C $BACKUP_DIR odoo_db_$DATE.sql.gz odoo_data_$DATE.tar.gz nginx_config_$DATE.tar.gz

# Verificar integridad de backups
log "Verificando integridad de backups..."
for file in $BACKUP_DIR/odoo_db_$DATE.sql.gz $BACKUP_DIR/odoo_data_$DATE.tar.gz; do
    if gzip -t "$file" 2>/dev/null; then
        log "✓ $file - OK"
    else
        error "✗ $file - CORRUPTO"
    fi
done

# Subir a S3 (si está configurado)
if [ -n "$S3_BUCKET" ]; then
    log "Subiendo backups a S3..."
    
    # Verificar que AWS CLI esté disponible y configurado
    if command -v aws >/dev/null 2>&1; then
        aws s3 cp $BACKUP_DIR/complete_backup_$DATE.tar.gz s3://$S3_BUCKET/odoo-backups/ --region $AWS_REGION
        
        if [ $? -eq 0 ]; then
            log "Backup subido a S3: s3://$S3_BUCKET/odoo-backups/complete_backup_$DATE.tar.gz"
        else
            log "Warning: Error subiendo a S3"
        fi
    else
        log "Warning: AWS CLI no disponible, saltando subida a S3"
    fi
fi

# Limpiar backups antiguos locales
log "Limpiando backups antiguos..."
find $BACKUP_DIR -name "*.gz" -mtime +$RETENTION_DAYS -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete

# Limpiar backups antiguos en S3 (si está configurado)
if [ -n "$S3_BUCKET" ] && command -v aws >/dev/null 2>&1; then
    CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)
    aws s3 ls s3://$S3_BUCKET/odoo-backups/ --region $AWS_REGION | while read -r line; do
        file_date=$(echo $line | awk '{print $1}')
        file_name=$(echo $line | awk '{print $4}')
        
        if [[ "$file_date" < "$CUTOFF_DATE" ]]; then
            aws s3 rm s3://$S3_BUCKET/odoo-backups/$file_name --region $AWS_REGION
            log "Eliminado de S3: $file_name"
        fi
    done
fi

# Estadísticas finales
BACKUP_SIZE=$(du -sh $BACKUP_DIR/complete_backup_$DATE.tar.gz | cut -f1)
DISK_USAGE=$(df -h $BACKUP_DIR | tail -1 | awk '{print $5}')

log "Backup completado exitosamente"
log "Tamaño del backup: $BACKUP_SIZE"
log "Uso de disco: $DISK_USAGE"
log "Archivos creados:"
log "  - odoo_db_$DATE.sql.gz (Base de datos)"
log "  - odoo_data_$DATE.tar.gz (Datos de Odoo)"
log "  - nginx_config_$DATE.tar.gz (Configuración nginx)"
log "  - complete_backup_$DATE.tar.gz (Backup completo)"

# Enviar notificación (si está configurado)
if [ -n "$WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"✅ Backup de Odoo completado - $DATE\nTamaño: $BACKUP_SIZE\nUso de disco: $DISK_USAGE\"}" \
        "$WEBHOOK_URL" >/dev/null 2>&1 || log "Warning: Error enviando notificación"
fi

log "Script de backup finalizado"
