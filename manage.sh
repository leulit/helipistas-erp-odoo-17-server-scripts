#!/bin/bash

# Script de gestión y mantenimiento para Odoo en AWS
set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Obtener IP de la instancia
get_instance_ip() {
    cd terraform
    if [ -f terraform.tfstate ]; then
        terraform output -raw instance_public_ip 2>/dev/null || error "No se pudo obtener la IP de la instancia"
    else
        error "No se encontró terraform.tfstate. ¿Está desplegada la infraestructura?"
    fi
    cd ..
}

# Conectar por SSH
ssh_connect() {
    INSTANCE_IP=$(get_instance_ip)
    log "Conectando a la instancia: $INSTANCE_IP"
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP
}

# Verificar estado de servicios
check_status() {
    INSTANCE_IP=$(get_instance_ip)
    log "Verificando estado de servicios en: $INSTANCE_IP"
    
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP << 'EOF'
echo "=== Estado de Docker ==="
sudo docker ps

echo -e "\n=== Estado de Odoo ==="
sudo docker-compose -f /opt/odoo/docker-compose.yml ps

echo -e "\n=== Recursos del sistema ==="
free -h
df -h

echo -e "\n=== Últimos logs de Odoo ==="
sudo docker-compose -f /opt/odoo/docker-compose.yml logs --tail=20 odoo

echo -e "\n=== Estado de la red ==="
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost/health
EOF
}

# Ver logs en tiempo real
view_logs() {
    INSTANCE_IP=$(get_instance_ip)
    local service=${1:-""}
    
    if [ -n "$service" ]; then
        log "Viendo logs de $service en tiempo real..."
        ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "sudo docker-compose -f /opt/odoo/docker-compose.yml logs -f $service"
    else
        log "Viendo todos los logs en tiempo real..."
        ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "sudo docker-compose -f /opt/odoo/docker-compose.yml logs -f"
    fi
}

# Reiniciar servicios
restart_services() {
    INSTANCE_IP=$(get_instance_ip)
    local service=${1:-""}
    
    if [ -n "$service" ]; then
        log "Reiniciando servicio $service..."
        ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "sudo docker-compose -f /opt/odoo/docker-compose.yml restart $service"
    else
        log "Reiniciando todos los servicios..."
        ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "sudo docker-compose -f /opt/odoo/docker-compose.yml restart"
    fi
    
    log "Servicios reiniciados"
}

# Crear backup
create_backup() {
    INSTANCE_IP=$(get_instance_ip)
    log "Creando backup..."
    
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP << 'EOF'
cd /opt/odoo
sudo ./backup.sh
echo "Backup creado exitosamente"
EOF
    
    log "Backup completado"
}

# Descargar backup
download_backup() {
    INSTANCE_IP=$(get_instance_ip)
    local backup_file=${1:-""}
    
    log "Listando backups disponibles..."
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "ls -la /opt/odoo/backup/"
    
    if [ -n "$backup_file" ]; then
        log "Descargando backup: $backup_file"
        scp -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP:/opt/odoo/backup/$backup_file ./
        log "Backup descargado: ./$backup_file"
    else
        info "Especifica el nombre del archivo a descargar: $0 download-backup <archivo>"
    fi
}

# Actualizar contenedores manualmente
update_containers() {
    INSTANCE_IP=$(get_instance_ip)
    
    warning "ACTUALIZACIÓN MANUAL DE CONTENEDORES"
    info "Este proceso hará lo siguiente:"
    info "1. Creará un backup automático antes de actualizar"
    info "2. Descargará las últimas imágenes de contenedores"
    info "3. Recreará los contenedores con las nuevas imágenes"
    info "4. Limpiará imágenes no utilizadas"
    info ""
    warning "IMPORTANTE: Esto puede causar downtime temporal del servicio"
    
    read -p "¿Estás seguro de que quieres continuar? (escriba 'SI' para confirmar): " confirm
    if [ "$confirm" != "SI" ]; then
        error "Actualización cancelada por el usuario"
        return 1
    fi
    
    log "Creando backup de seguridad antes de actualizar..."
    create_backup
    
    log "Iniciando actualización de contenedores..."
    
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP << 'EOF'
cd /opt/odoo

echo "=== Estado antes de la actualización ==="
sudo docker-compose ps
echo ""

echo "=== Descargando nuevas imágenes ==="
sudo docker-compose pull
echo ""

echo "=== Recreando contenedores ==="
sudo docker-compose up -d --force-recreate
echo ""

echo "=== Esperando que los servicios estén listos ==="
sleep 30

echo "=== Estado después de la actualización ==="
sudo docker-compose ps
echo ""

echo "=== Limpiando imágenes no utilizadas ==="
sudo docker system prune -f
echo ""

echo "=== Verificando logs por errores ==="
sudo docker-compose logs --tail=50 | grep -i error || echo "No se encontraron errores en los logs recientes"
EOF
    
    log "Actualización completada - Verifica que todos los servicios estén funcionando correctamente"
    info "Usa '$0 status' para verificar el estado de los servicios"
    info "Usa '$0 logs' para revisar los logs si hay problemas"
}

# Monitoreo de recursos
monitor_resources() {
    INSTANCE_IP=$(get_instance_ip)
    log "Monitoreando recursos (Ctrl+C para salir)..."
    
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP << 'EOF'
while true; do
    clear
    echo "=== $(date) ==="
    echo ""
    echo "=== CPU y Memoria ==="
    top -bn1 | head -n 15
    
    echo -e "\n=== Espacio en disco ==="
    df -h
    
    echo -e "\n=== Docker Stats ==="
    docker stats --no-stream
    
    echo -e "\n=== Conexiones de red ==="
    netstat -an | grep :80 | wc -l | xargs echo "Conexiones HTTP:"
    netstat -an | grep :443 | wc -l | xargs echo "Conexiones HTTPS:"
    
    sleep 5
done
EOF
}

# Configurar SSL con Let's Encrypt
setup_ssl() {
    local domain=${1:-""}
    local email=${2:-""}
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        error "Uso: $0 setup-ssl <dominio> <email>"
    fi
    
    INSTANCE_IP=$(get_instance_ip)
    log "Configurando SSL para $domain..."
    
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP << EOF
# Detener nginx
sudo docker-compose -f /opt/odoo/docker-compose.yml stop nginx

# Instalar certbot si no está instalado
sudo yum install -y certbot

# Obtener certificado
sudo certbot certonly --standalone -d $domain --email $email --agree-tos --non-interactive

# Copiar certificados
sudo mkdir -p /opt/odoo/nginx/ssl
sudo cp /etc/letsencrypt/live/$domain/fullchain.pem /opt/odoo/nginx/ssl/
sudo cp /etc/letsencrypt/live/$domain/privkey.pem /opt/odoo/nginx/ssl/
sudo chown -R ec2-user:ec2-user /opt/odoo/nginx/ssl

# Actualizar configuración de nginx para SSL
sudo cp /opt/odoo/nginx/ssl.conf.example /opt/odoo/nginx/conf/default.conf
sudo sed -i "s/tu-dominio.com/$domain/g" /opt/odoo/nginx/conf/default.conf

# Configurar auto-renovación
echo "0 12 * * * /usr/bin/certbot renew --quiet && docker-compose -f /opt/odoo/docker-compose.yml restart nginx" | sudo crontab -

# Reiniciar nginx
sudo docker-compose -f /opt/odoo/docker-compose.yml start nginx
EOF
    
    log "SSL configurado para $domain"
}

# Ejecutar comando remoto
remote_command() {
    INSTANCE_IP=$(get_instance_ip)
    local command="$*"
    
    if [ -z "$command" ]; then
        error "Uso: $0 remote '<comando>'"
    fi
    
    log "Ejecutando comando remoto: $command"
    ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP "$command"
}

# Mostrar información de conexión
show_info() {
    if [ ! -f deployment-info.txt ]; then
        error "Archivo deployment-info.txt no encontrado. ¿Está desplegada la infraestructura?"
    fi
    
    cat deployment-info.txt
}

# Escanear recursos de AWS
scan_aws_resources() {
    log "Escaneando recursos de AWS..."
    if [ -f "./cleanup.sh" ]; then
        ./cleanup.sh --dry-run
    else
        error "Script de limpieza no encontrado"
    fi
}

# Limpiar recursos de AWS
cleanup_aws_resources() {
    warn "Esta operación eliminará TODOS los recursos de AWS del proyecto"
    if [ -f "./cleanup.sh" ]; then
        ./cleanup.sh "$@"
    else
        error "Script de limpieza no encontrado"
    fi
}

# Verificar costos actuales
check_costs() {
    log "Verificando costos estimados..."
    if [ -f "./cleanup.sh" ]; then
        ./cleanup.sh --dry-run | grep -A 10 "Costos estimados"
    else
        # Estimación básica sin el script
        INSTANCE_IP=$(get_instance_ip)
        if [ -n "$INSTANCE_IP" ]; then
            info "Instancia activa en: $INSTANCE_IP"
            info "Costo estimado: ~\$0.04-0.08/hora (~\$30-60/mes)"
        fi
    fi
}

# Mostrar ayuda
show_help() {
    echo "Script de gestión de Odoo en AWS"
    echo ""
    echo "Uso: $0 <comando> [argumentos]"
    echo ""
    echo "Comandos disponibles:"
    echo "  ssh                    Conectar por SSH a la instancia"
    echo "  status                 Verificar estado de servicios"
    echo "  logs [servicio]        Ver logs (odoo, postgresql, nginx)"
    echo "  restart [servicio]     Reiniciar servicios"
    echo "  backup                 Crear backup de la base de datos"
    echo "  download-backup <archivo>  Descargar backup específico"
    echo "  update                 Actualizar contenedores (requiere confirmación y crea backup)"
    echo "  monitor                Monitorear recursos en tiempo real"
    echo "  setup-ssl <dominio> <email>  Configurar SSL con Let's Encrypt"
    echo "  remote '<comando>'     Ejecutar comando remoto"
    echo "  info                   Mostrar información de conexión"
    echo "  scan                   Escanear recursos de AWS (sin eliminar)"
    echo "  cleanup [--force]      Limpiar TODOS los recursos de AWS"
    echo "  costs                  Ver costos estimados actuales"
    echo "  -h, --help             Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 status"
    echo "  $0 logs odoo"
    echo "  $0 restart nginx"
    echo "  $0 setup-ssl midominio.com admin@midominio.com"
    echo "  $0 remote 'sudo docker ps'"
    echo "  $0 scan                # Ver recursos sin eliminar"
    echo "  $0 cleanup --force     # PELIGROSO: Eliminar todo"
}

# Main script
main() {
    case "${1:-}" in
        ssh)
            ssh_connect
            ;;
        status)
            check_status
            ;;
        logs)
            view_logs "${2:-}"
            ;;
        restart)
            restart_services "${2:-}"
            ;;
        backup)
            create_backup
            ;;
        download-backup)
            download_backup "${2:-}"
            ;;
        update)
            update_containers
            ;;
        monitor)
            monitor_resources
            ;;
        setup-ssl)
            setup_ssl "${2:-}" "${3:-}"
            ;;
        remote)
            shift
            remote_command "$@"
            ;;
        info)
            show_info
            ;;
        scan)
            scan_aws_resources
            ;;
        cleanup)
            shift
            cleanup_aws_resources "$@"
            ;;
        costs)
            check_costs
            ;;
        -h|--help)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            error "Comando desconocido: $1. Usa -h para ver la ayuda."
            ;;
    esac
}

# Ejecutar script principal
main "$@"
