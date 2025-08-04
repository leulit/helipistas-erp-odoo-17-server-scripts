#!/bin/bash

# Script de despliegue completo para Odoo en AWS
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

# Verificar prerequisites
check_prerequisites() {
    log "Verificando prerequisites..."
    
    # Verificar Terraform
    if ! command -v terraform &> /dev/null; then
        error "Terraform no está instalado. Instálalo desde: https://terraform.io/downloads"
    fi
    
    # Verificar AWS CLI
    if ! command -v aws &> /dev/null; then
        error "AWS CLI no está instalado. Instálalo desde: https://aws.amazon.com/cli/"
    fi
    
    # Verificar configuración AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI no está configurado. Ejecuta: aws configure"
    fi
    
    # Verificar SSH key
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        warn "No se encontró clave SSH en ~/.ssh/id_rsa.pub"
        info "Generando nueva clave SSH..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    log "Prerequisites verificados correctamente"
}

# Configurar archivos de configuración
setup_config() {
    log "Configurando archivos de configuración..."
    
    cd terraform
    
    # Crear terraform.tfvars si no existe
    if [ ! -f terraform.tfvars ]; then
        log "Creando terraform.tfvars..."
        cp terraform.tfvars.example terraform.tfvars
        
        # Generar contraseñas seguras
        POSTGRES_PASS=$(openssl rand -base64 32)
        ODOO_PASS=$(openssl rand -base64 32)
        
        # Obtener clave SSH pública
        SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
        
        # Actualizar terraform.tfvars (acceso abierto desde cualquier IP)
        sed -i.bak "s/public_key = .*/public_key = \"$SSH_KEY\"/" terraform.tfvars
        sed -i.bak "s/allowed_ssh_cidr = .*/allowed_ssh_cidr = \"0.0.0.0\/0\"/" terraform.tfvars
        sed -i.bak "s/odoo_master_password = .*/odoo_master_password = \"$ODOO_PASS\"/" terraform.tfvars
        sed -i.bak "s/postgres_password = .*/postgres_password = \"$POSTGRES_PASS\"/" terraform.tfvars
        
        info "Configuración básica completada. Edita terraform.tfvars para personalizar."
        info "Contraseñas generadas automáticamente - guárdalas en un lugar seguro:"
        info "PostgreSQL: $POSTGRES_PASS"
        info "Odoo Master: $ODOO_PASS"
    fi
    
    cd ..
}

# Desplegar infraestructura
deploy_infrastructure() {
    log "Desplegando infraestructura en AWS..."
    
    cd terraform
    
    # Inicializar Terraform
    log "Inicializando Terraform..."
    terraform init
    
    # Planificar despliegue
    log "Creando plan de despliegue..."
    terraform plan -out=tfplan
    
    # Aplicar cambios
    log "Aplicando cambios en AWS..."
    terraform apply tfplan
    
    # Obtener outputs
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    SSH_COMMAND=$(terraform output -raw ssh_command)
    ODOO_URL=$(terraform output -raw odoo_url)
    
    log "Infraestructura desplegada exitosamente!"
    info "IP de la instancia: $INSTANCE_IP"
    info "Comando SSH: $SSH_COMMAND"
    info "URL de Odoo: $ODOO_URL"
    
    # Esperar a que la instancia esté lista
    log "Esperando a que la instancia esté completamente configurada..."
    log "Esto puede tomar 5-10 minutos..."
    
    # Crear archivo de información
    cat > ../deployment-info.txt << EOF
Información de Despliegue de Odoo
================================

Fecha de despliegue: $(date)
IP de la instancia: $INSTANCE_IP
Comando SSH: $SSH_COMMAND
URL de Odoo: $ODOO_URL

Contraseñas (guardar en lugar seguro):
$(grep -E "(odoo_master_password|postgres_password)" terraform.tfvars)

Para conectarse:
$SSH_COMMAND

Para verificar el estado:
ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP 'sudo /opt/odoo/status.sh'

Para ver logs:
ssh -i ~/.ssh/id_rsa ec2-user@$INSTANCE_IP 'sudo docker-compose -f /opt/odoo/docker-compose.yml logs -f'
EOF
    
    cd ..
}

# Verificar despliegue
verify_deployment() {
    log "Verificando despliegue..."
    
    cd terraform
    INSTANCE_IP=$(terraform output -raw instance_public_ip)
    cd ..
    
    # Esperar a que SSH esté disponible
    log "Esperando a que SSH esté disponible..."
    timeout=300
    while ! nc -z $INSTANCE_IP 22; do
        sleep 5
        timeout=$((timeout-5))
        if [ $timeout -le 0 ]; then
            error "Timeout esperando SSH"
        fi
    done
    
    # Esperar a que Odoo esté disponible
    log "Esperando a que Odoo esté disponible..."
    timeout=600
    while ! curl -s --connect-timeout 5 http://$INSTANCE_IP/web/health &> /dev/null; do
        sleep 10
        timeout=$((timeout-10))
        if [ $timeout -le 0 ]; then
            warn "Timeout esperando Odoo, pero la instancia puede estar configurándose aún"
            break
        fi
    done
    
    if curl -s --connect-timeout 5 http://$INSTANCE_IP/web/health &> /dev/null; then
        log "¡Odoo está funcionando correctamente!"
        log "Puedes acceder en: http://$INSTANCE_IP"
    else
        warn "Odoo podría estar configurándose aún. Verifica en unos minutos."
    fi
}

# Mostrar ayuda
show_help() {
    echo "Script de despliegue de Odoo en AWS"
    echo ""
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -h, --help     Mostrar esta ayuda"
    echo "  -c, --check    Solo verificar prerequisites"
    echo "  -p, --plan     Solo crear plan de Terraform"
    echo "  -d, --deploy   Desplegar infraestructura completa"
    echo "  -v, --verify   Verificar despliegue existente"
    echo "  --destroy      Destruir infraestructura (PELIGROSO)"
    echo "  --cleanup      Limpieza manual de recursos AWS"
    echo "  --scan         Escanear recursos AWS sin eliminar"
    echo ""
    echo "Sin argumentos ejecuta el despliegue completo"
    echo ""
    echo "⚠️  IMPORTANTE para pruebas:"
    echo "  --scan         Ver qué recursos están creados"
    echo "  --cleanup      Eliminar TODOS los recursos (manual)"
    echo "  --destroy      Eliminar con Terraform (recomendado)"
}

# Destruir infraestructura
destroy_infrastructure() {
    warn "¡ADVERTENCIA! Esto destruirá toda la infraestructura en AWS"
    
    # Mostrar recursos antes de eliminar
    log "Escaneando recursos actuales..."
    if [ -f "./cleanup.sh" ]; then
        ./cleanup.sh --dry-run
    fi
    
    echo ""
    read -p "¿Estás seguro? (escribe 'DELETE' para confirmar): " confirm
    
    if [ "$confirm" = "DELETE" ]; then
        log "Destruyendo infraestructura..."
        
        # Intentar con Terraform primero
        if [ -f "terraform/terraform.tfstate" ]; then
            log "Usando Terraform para destruir recursos..."
            cd terraform
            terraform destroy -auto-approve
            cd ..
            
            # Verificar que todo se eliminó
            log "Verificando limpieza..."
            sleep 10
            if [ -f "./cleanup.sh" ]; then
                ./cleanup.sh --dry-run
            fi
        else
            warn "No se encontró estado de Terraform"
            if [ -f "./cleanup.sh" ]; then
                log "Usando script de limpieza manual..."
                ./cleanup.sh --force
            fi
        fi
        
        # Limpiar archivos locales
        log "Limpiando archivos locales..."
        rm -f deployment-info.txt
        rm -f terraform/terraform.tfstate*
        rm -f terraform/tfplan
        
        log "✅ Infraestructura destruida completamente"
    else
        info "Operación cancelada"
    fi
}

# Main script
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -c|--check)
            check_prerequisites
            ;;
        -p|--plan)
            check_prerequisites
            setup_config
            cd terraform
            terraform init
            terraform plan
            cd ..
            ;;
        -d|--deploy)
            check_prerequisites
            setup_config
            deploy_infrastructure
            ;;
        -v|--verify)
            verify_deployment
            ;;
        --destroy)
            destroy_infrastructure
            ;;
        --cleanup)
            if [ -f "./cleanup.sh" ]; then
                ./cleanup.sh "$@"
            else
                error "Script de limpieza no encontrado"
            fi
            ;;
        --scan)
            if [ -f "./cleanup.sh" ]; then
                ./cleanup.sh --dry-run
            else
                error "Script de limpieza no encontrado"
            fi
            ;;
        "")
            log "Iniciando despliegue completo de Odoo en AWS..."
            check_prerequisites
            setup_config
            deploy_infrastructure
            verify_deployment
            log "¡Despliegue completado!"
            ;;
        *)
            error "Opción desconocida: $1. Usa -h para ver la ayuda."
            ;;
    esac
}

# Ejecutar script principal
main "$@"
