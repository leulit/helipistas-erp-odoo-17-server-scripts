#!/bin/bash

# Script de monitoreo para Odoo en AWS
# Se ejecuta periódicamente para verificar el estado del sistema

set -e

# Configuración
LOG_FILE="/var/log/odoo-monitor.log"
ALERT_WEBHOOK="${WEBHOOK_URL:-}"
EMAIL_ALERTS="${EMAIL_ALERTS:-}"
CPU_THRESHOLD=80
MEMORY_THRESHOLD=85
DISK_THRESHOLD=85
RESPONSE_TIME_THRESHOLD=5000  # en milisegundos

# Función de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

error() {
    echo "[ERROR $(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

warn() {
    echo "[WARNING $(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOG_FILE
}

# Función para enviar alertas
send_alert() {
    local message="$1"
    local severity="$2"  # info, warning, error, critical
    
    log "ALERT [$severity]: $message"
    
    # Webhook (Slack, Discord, etc.)
    if [ -n "$ALERT_WEBHOOK" ]; then
        local emoji="ℹ️"
        case $severity in
            warning) emoji="⚠️" ;;
            error) emoji="❌" ;;
            critical) emoji="🚨" ;;
        esac
        
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$emoji **Odoo Monitor - $severity**\n$message\"}" \
            "$ALERT_WEBHOOK" >/dev/null 2>&1 || log "Error enviando webhook"
    fi
    
    # Email (si está configurado)
    if [ -n "$EMAIL_ALERTS" ]; then
        echo "$message" | mail -s "Odoo Monitor Alert - $severity" "$EMAIL_ALERTS" 2>/dev/null || log "Error enviando email"
    fi
}

# Verificar estado de contenedores Docker
check_containers() {
    local issues=0
    
    log "Verificando estado de contenedores..."
    
    for container in odoo_postgresql odoo_app odoo_nginx; do
        if ! docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            error "Contenedor $container no está ejecutándose"
            send_alert "Contenedor $container no está ejecutándose" "critical"
            issues=$((issues + 1))
        fi
    done
    
    # Verificar health checks
    for container in odoo_postgresql odoo_app odoo_nginx; do
        health=$(docker inspect --format='{{.State.Health.Status}}' $container 2>/dev/null || echo "no-health-check")
        if [ "$health" = "unhealthy" ]; then
            error "Contenedor $container no está saludable"
            send_alert "Contenedor $container falló el health check" "error"
            issues=$((issues + 1))
        fi
    done
    
    if [ $issues -eq 0 ]; then
        log "✓ Todos los contenedores están funcionando correctamente"
    fi
    
    return $issues
}

# Verificar recursos del sistema
check_system_resources() {
    local issues=0
    
    log "Verificando recursos del sistema..."
    
    # CPU Usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F% '{print $1}')
    cpu_usage=${cpu_usage%.*}  # Quitar decimales
    
    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        warn "Uso de CPU alto: ${cpu_usage}%"
        send_alert "Uso de CPU alto: ${cpu_usage}% (umbral: ${CPU_THRESHOLD}%)" "warning"
        issues=$((issues + 1))
    else
        log "✓ Uso de CPU: ${cpu_usage}%"
    fi
    
    # Memory Usage
    memory_info=$(free | grep Mem)
    total_mem=$(echo $memory_info | awk '{print $2}')
    used_mem=$(echo $memory_info | awk '{print $3}')
    memory_percent=$((used_mem * 100 / total_mem))
    
    if [ "$memory_percent" -gt "$MEMORY_THRESHOLD" ]; then
        warn "Uso de memoria alto: ${memory_percent}%"
        send_alert "Uso de memoria alto: ${memory_percent}% (umbral: ${MEMORY_THRESHOLD}%)" "warning"
        issues=$((issues + 1))
    else
        log "✓ Uso de memoria: ${memory_percent}%"
    fi
    
    # Disk Usage
    disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        warn "Uso de disco alto: ${disk_usage}%"
        send_alert "Uso de disco alto: ${disk_usage}% (umbral: ${DISK_THRESHOLD}%)" "warning"
        issues=$((issues + 1))
    else
        log "✓ Uso de disco: ${disk_usage}%"
    fi
    
    return $issues
}

# Verificar conectividad de Odoo
check_odoo_connectivity() {
    local issues=0
    
    log "Verificando conectividad de Odoo..."
    
    # Test HTTP health endpoint
    start_time=$(date +%s%3N)
    if curl -s --connect-timeout 10 --max-time 30 http://localhost/health > /dev/null; then
        end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))
        
        if [ "$response_time" -gt "$RESPONSE_TIME_THRESHOLD" ]; then
            warn "Tiempo de respuesta lento: ${response_time}ms"
            send_alert "Tiempo de respuesta lento: ${response_time}ms (umbral: ${RESPONSE_TIME_THRESHOLD}ms)" "warning"
            issues=$((issues + 1))
        else
            log "✓ Odoo responde correctamente (${response_time}ms)"
        fi
    else
        error "Odoo no responde en el endpoint de salud"
        send_alert "Odoo no responde en el endpoint de salud" "critical"
        issues=$((issues + 1))
    fi
    
    # Test database connectivity
    if docker exec odoo_postgresql pg_isready -U odoo > /dev/null 2>&1; then
        log "✓ Base de datos PostgreSQL disponible"
    else
        error "Base de datos PostgreSQL no disponible"
        send_alert "Base de datos PostgreSQL no disponible" "critical"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Verificar logs de errores
check_error_logs() {
    local issues=0
    
    log "Verificando logs de errores..."
    
    # Buscar errores críticos en logs de Odoo (últimos 5 minutos)
    error_count=$(docker logs --since=5m odoo_app 2>&1 | grep -i "error\|exception\|traceback" | wc -l)
    
    if [ "$error_count" -gt 10 ]; then
        warn "Alto número de errores en logs de Odoo: $error_count"
        send_alert "Alto número de errores en logs de Odoo: $error_count en los últimos 5 minutos" "warning"
        issues=$((issues + 1))
    elif [ "$error_count" -gt 0 ]; then
        log "Errores encontrados en logs de Odoo: $error_count"
    else
        log "✓ No se encontraron errores recientes en logs de Odoo"
    fi
    
    # Verificar logs de nginx
    if [ -f "/opt/odoo/nginx/logs/error.log" ]; then
        nginx_errors=$(tail -n 100 /opt/odoo/nginx/logs/error.log | grep "$(date +'%Y/%m/%d %H:%M')" | wc -l)
        if [ "$nginx_errors" -gt 5 ]; then
            warn "Errores en nginx: $nginx_errors"
            send_alert "Errores en nginx en el último minuto: $nginx_errors" "warning"
            issues=$((issues + 1))
        fi
    fi
    
    return $issues
}

# Verificar backups
check_backups() {
    local issues=0
    
    log "Verificando backups..."
    
    # Verificar que existe al menos un backup reciente (últimas 24 horas)
    recent_backup=$(find /opt/odoo/backup -name "*.tar.gz" -mtime -1 | wc -l)
    
    if [ "$recent_backup" -eq 0 ]; then
        warn "No se encontraron backups recientes (últimas 24 horas)"
        send_alert "No se encontraron backups recientes (últimas 24 horas)" "warning"
        issues=$((issues + 1))
    else
        log "✓ Backups recientes encontrados: $recent_backup"
    fi
    
    # Verificar espacio en directorio de backup
    backup_disk_usage=$(df /opt/odoo/backup | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$backup_disk_usage" -gt 90 ]; then
        warn "Poco espacio en directorio de backup: ${backup_disk_usage}%"
        send_alert "Poco espacio en directorio de backup: ${backup_disk_usage}%" "warning"
        issues=$((issues + 1))
    fi
    
    return $issues
}

# Verificar actualizaciones de seguridad
check_security_updates() {
    local issues=0
    
    log "Verificando actualizaciones de seguridad..."
    
    # Verificar actualizaciones del sistema
    security_updates=$(yum check-update --security 2>/dev/null | grep -c "^[a-zA-Z]" || echo "0")
    
    if [ "$security_updates" -gt 0 ]; then
        warn "Actualizaciones de seguridad disponibles: $security_updates"
        send_alert "Actualizaciones de seguridad disponibles: $security_updates" "info"
        issues=$((issues + 1))
    else
        log "✓ No hay actualizaciones de seguridad pendientes"
    fi
    
    return $issues
}

# Generar reporte de estado
generate_status_report() {
    local total_issues=$1
    
    cat > /tmp/odoo_status_report.txt << EOF
Reporte de Estado de Odoo - $(date)
=====================================

Resumen:
- Total de problemas encontrados: $total_issues
- Estado general: $([ $total_issues -eq 0 ] && echo "✅ SALUDABLE" || echo "⚠️ REQUIERE ATENCIÓN")

Recursos del Sistema:
- CPU: ${cpu_usage:-N/A}%
- Memoria: ${memory_percent:-N/A}%
- Disco: ${disk_usage:-N/A}%

Servicios:
- PostgreSQL: $(docker exec odoo_postgresql pg_isready -U odoo >/dev/null 2>&1 && echo "✅ OK" || echo "❌ ERROR")
- Odoo: $(curl -s --connect-timeout 5 http://localhost/health >/dev/null && echo "✅ OK" || echo "❌ ERROR")
- Nginx: $(docker ps --format "table {{.Names}}" | grep -q "odoo_nginx" && echo "✅ OK" || echo "❌ ERROR")

Backups:
- Backups recientes (24h): ${recent_backup:-N/A}
- Espacio backup: ${backup_disk_usage:-N/A}%

Últimos errores en logs:
$(docker logs --since=10m odoo_app 2>&1 | grep -i "error\|exception" | tail -5 || echo "No hay errores recientes")

Para más detalles, revisa: $LOG_FILE
EOF
    
    # Enviar reporte si hay problemas o si es un reporte programado
    if [ "$total_issues" -gt 0 ] || [ "${1:-}" = "--force-report" ]; then
        if [ -n "$ALERT_WEBHOOK" ]; then
            send_alert "$(cat /tmp/odoo_status_report.txt)" "info"
        fi
    fi
}

# Función principal
main() {
    local total_issues=0
    
    log "=== Iniciando monitoreo de Odoo ==="
    
    check_containers
    total_issues=$((total_issues + $?))
    
    check_system_resources
    total_issues=$((total_issues + $?))
    
    check_odoo_connectivity
    total_issues=$((total_issues + $?))
    
    check_error_logs
    total_issues=$((total_issues + $?))
    
    check_backups
    total_issues=$((total_issues + $?))
    
    check_security_updates
    total_issues=$((total_issues + $?))
    
    generate_status_report $total_issues "$1"
    
    log "=== Monitoreo completado. Problemas encontrados: $total_issues ==="
    
    # Cleanup de logs antiguos
    find $LOG_FILE -mtime +30 -delete 2>/dev/null || true
    
    return $total_issues
}

# Mostrar ayuda
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    echo "Script de monitoreo de Odoo"
    echo ""
    echo "Uso: $0 [--force-report]"
    echo ""
    echo "Variables de entorno:"
    echo "  WEBHOOK_URL       - URL para notificaciones webhook"
    echo "  EMAIL_ALERTS      - Email para alertas"
    echo "  CPU_THRESHOLD     - Umbral de CPU (default: 80%)"
    echo "  MEMORY_THRESHOLD  - Umbral de memoria (default: 85%)"
    echo "  DISK_THRESHOLD    - Umbral de disco (default: 85%)"
    echo ""
    echo "El script verifica:"
    echo "  - Estado de contenedores Docker"
    echo "  - Recursos del sistema (CPU, memoria, disco)"
    echo "  - Conectividad de Odoo y PostgreSQL"
    echo "  - Errores en logs"
    echo "  - Estado de backups"
    echo "  - Actualizaciones de seguridad"
    exit 0
fi

# Ejecutar monitoreo
main "$@"
