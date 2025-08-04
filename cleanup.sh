#!/bin/bash

# Script de limpieza completa de recursos AWS
# Elimina TODOS los recursos creados para el proyecto Helipistas Odoo

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

# Variables
PROJECT_NAME="helipistas-odoo"
AWS_REGION="us-east-1"

# Función para verificar AWS CLI
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        error "AWS CLI no está instalado"
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS CLI no está configurado. Ejecuta: aws configure"
    fi
    
    log "AWS CLI configurado correctamente"
}

# Función para obtener recursos por tags
get_resources_by_tag() {
    local resource_type="$1"
    local tag_key="Project"
    local tag_value="$PROJECT_NAME"
    
    case $resource_type in
        "instances")
            aws ec2 describe-instances \
                --filters "Name=tag:$tag_key,Values=$tag_value" "Name=instance-state-name,Values=running,stopped,pending" \
                --query 'Reservations[].Instances[].InstanceId' \
                --output text --region $AWS_REGION
            ;;
        "spot-requests")
            aws ec2 describe-spot-instance-requests \
                --filters "Name=tag:$tag_key,Values=$tag_value" "Name=state,Values=active,open" \
                --query 'SpotInstanceRequests[].SpotInstanceRequestId' \
                --output text --region $AWS_REGION
            ;;
        "security-groups")
            aws ec2 describe-security-groups \
                --filters "Name=tag:$tag_key,Values=$tag_value" \
                --query 'SecurityGroups[].GroupId' \
                --output text --region $AWS_REGION
            ;;
        "vpcs")
            aws ec2 describe-vpcs \
                --filters "Name=tag:$tag_key,Values=$tag_value" \
                --query 'Vpcs[].VpcId' \
                --output text --region $AWS_REGION
            ;;
        "subnets")
            aws ec2 describe-subnets \
                --filters "Name=tag:$tag_key,Values=$tag_value" \
                --query 'Subnets[].SubnetId' \
                --output text --region $AWS_REGION
            ;;
        "internet-gateways")
            aws ec2 describe-internet-gateways \
                --filters "Name=tag:$tag_key,Values=$tag_value" \
                --query 'InternetGateways[].InternetGatewayId' \
                --output text --region $AWS_REGION
            ;;
        "route-tables")
            aws ec2 describe-route-tables \
                --filters "Name=tag:$tag_key,Values=$tag_value" \
                --query 'RouteTables[].RouteTableId' \
                --output text --region $AWS_REGION
            ;;
        "key-pairs")
            aws ec2 describe-key-pairs \
                --filters "Name=key-name,Values=${PROJECT_NAME}*" \
                --query 'KeyPairs[].KeyName' \
                --output text --region $AWS_REGION
            ;;
        "elastic-ips")
            aws ec2 describe-addresses \
                --filters "Name=tag:$tag_key,Values=$tag_value" \
                --query 'Addresses[].AllocationId' \
                --output text --region $AWS_REGION
            ;;
        "volumes")
            aws ec2 describe-volumes \
                --filters "Name=tag:$tag_key,Values=$tag_value" \
                --query 'Volumes[].VolumeId' \
                --output text --region $AWS_REGION
            ;;
    esac
}

# Función para mostrar recursos encontrados
show_resources() {
    log "Escaneando recursos de AWS para el proyecto: $PROJECT_NAME"
    
    local found_resources=false
    
    # Instancias EC2
    local instances=$(get_resources_by_tag "instances")
    if [ -n "$instances" ]; then
        echo -e "${YELLOW}📦 Instancias EC2 encontradas:${NC}"
        for instance in $instances; do
            local instance_info=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[0].Instances[0].[InstanceType,State.Name,PublicIpAddress]' --output text --region $AWS_REGION)
            echo "  - $instance ($instance_info)"
        done
        found_resources=true
    fi
    
    # Spot Instance Requests
    local spot_requests=$(get_resources_by_tag "spot-requests")
    if [ -n "$spot_requests" ]; then
        echo -e "${YELLOW}💰 Spot Instance Requests encontradas:${NC}"
        for request in $spot_requests; do
            echo "  - $request"
        done
        found_resources=true
    fi
    
    # Elastic IPs
    local eips=$(get_resources_by_tag "elastic-ips")
    if [ -n "$eips" ]; then
        echo -e "${YELLOW}🌐 Elastic IPs encontradas:${NC}"
        for eip in $eips; do
            local eip_info=$(aws ec2 describe-addresses --allocation-ids $eip --query 'Addresses[0].PublicIp' --output text --region $AWS_REGION)
            echo "  - $eip ($eip_info)"
        done
        found_resources=true
    fi
    
    # Volúmenes EBS
    local volumes=$(get_resources_by_tag "volumes")
    if [ -n "$volumes" ]; then
        echo -e "${YELLOW}💾 Volúmenes EBS encontrados:${NC}"
        for volume in $volumes; do
            local volume_info=$(aws ec2 describe-volumes --volume-ids $volume --query 'Volumes[0].[Size,State]' --output text --region $AWS_REGION)
            echo "  - $volume ($volume_info GB)"
        done
        found_resources=true
    fi
    
    # Security Groups
    local sgs=$(get_resources_by_tag "security-groups")
    if [ -n "$sgs" ]; then
        echo -e "${YELLOW}🔒 Security Groups encontrados:${NC}"
        for sg in $sgs; do
            echo "  - $sg"
        done
        found_resources=true
    fi
    
    # VPCs
    local vpcs=$(get_resources_by_tag "vpcs")
    if [ -n "$vpcs" ]; then
        echo -e "${YELLOW}🏗️  VPCs encontradas:${NC}"
        for vpc in $vpcs; do
            echo "  - $vpc"
        done
        found_resources=true
    fi
    
    # Key Pairs
    local keys=$(get_resources_by_tag "key-pairs")
    if [ -n "$keys" ]; then
        echo -e "${YELLOW}🔑 Key Pairs encontrados:${NC}"
        for key in $keys; do
            echo "  - $key"
        done
        found_resources=true
    fi
    
    if [ "$found_resources" = false ]; then
        info "✅ No se encontraron recursos de AWS para el proyecto $PROJECT_NAME"
        return 1
    fi
    
    return 0
}

# Función para calcular costos estimados
estimate_costs() {
    local instances=$(get_resources_by_tag "instances")
    local eips=$(get_resources_by_tag "elastic-ips")
    local volumes=$(get_resources_by_tag "volumes")
    
    local total_cost=0
    
    if [ -n "$instances" ]; then
        for instance in $instances; do
            local instance_type=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[0].Instances[0].InstanceType' --output text --region $AWS_REGION)
            local state=$(aws ec2 describe-instances --instance-ids $instance --query 'Reservations[0].Instances[0].State.Name' --output text --region $AWS_REGION)
            
            if [ "$state" = "running" ]; then
                case $instance_type in
                    "t3.small") total_cost=$(echo "$total_cost + 0.0208" | bc -l) ;;
                    "t3.medium") total_cost=$(echo "$total_cost + 0.0416" | bc -l) ;;
                    "t3.large") total_cost=$(echo "$total_cost + 0.0832" | bc -l) ;;
                esac
            fi
        done
    fi
    
    if [ -n "$eips" ]; then
        local eip_count=$(echo "$eips" | wc -w)
        total_cost=$(echo "$total_cost + ($eip_count * 0.005)" | bc -l)
    fi
    
    if [ -n "$volumes" ]; then
        for volume in $volumes; do
            local size=$(aws ec2 describe-volumes --volume-ids $volume --query 'Volumes[0].Size' --output text --region $AWS_REGION)
            total_cost=$(echo "$total_cost + ($size * 0.10 / 720)" | bc -l)
        done
    fi
    
    if (( $(echo "$total_cost > 0" | bc -l) )); then
        local hourly_cost=$(printf "%.4f" $total_cost)
        local daily_cost=$(echo "$total_cost * 24" | bc -l)
        local monthly_cost=$(echo "$total_cost * 720" | bc -l)
        
        warn "💰 Costos estimados de recursos activos:"
        echo "  - Por hora: \$${hourly_cost}"
        echo "  - Por día: \$$(printf "%.2f" $daily_cost)"
        echo "  - Por mes: \$$(printf "%.2f" $monthly_cost)"
    fi
}

# Función de limpieza con Terraform
terraform_cleanup() {
    log "Intentando limpieza con Terraform..."
    
    if [ -f "terraform/terraform.tfstate" ]; then
        log "Estado de Terraform encontrado, ejecutando destroy..."
        cd terraform
        terraform destroy -auto-approve
        cd ..
        log "✅ Limpieza con Terraform completada"
        return 0
    else
        warn "No se encontró estado de Terraform, procediendo con limpieza manual"
        return 1
    fi
}

# Función de limpieza manual
manual_cleanup() {
    log "Iniciando limpieza manual de recursos AWS..."
    
    # 1. Terminar instancias EC2
    local instances=$(get_resources_by_tag "instances")
    if [ -n "$instances" ]; then
        log "Terminando instancias EC2..."
        aws ec2 terminate-instances --instance-ids $instances --region $AWS_REGION
        
        # Esperar a que las instancias se terminen
        log "Esperando a que las instancias se terminen..."
        aws ec2 wait instance-terminated --instance-ids $instances --region $AWS_REGION
        log "✅ Instancias terminadas"
    fi
    
    # 2. Cancelar Spot Instance Requests
    local spot_requests=$(get_resources_by_tag "spot-requests")
    if [ -n "$spot_requests" ]; then
        log "Cancelando Spot Instance Requests..."
        aws ec2 cancel-spot-instance-requests --spot-instance-request-ids $spot_requests --region $AWS_REGION
        log "✅ Spot requests cancelados"
    fi
    
    # 3. Liberar Elastic IPs
    local eips=$(get_resources_by_tag "elastic-ips")
    if [ -n "$eips" ]; then
        log "Liberando Elastic IPs..."
        for eip in $eips; do
            aws ec2 release-address --allocation-id $eip --region $AWS_REGION
        done
        log "✅ Elastic IPs liberadas"
    fi
    
    # 4. Eliminar volúmenes EBS (los no asociados a instancias)
    sleep 30  # Esperar a que las instancias liberen los volúmenes
    local volumes=$(get_resources_by_tag "volumes")
    if [ -n "$volumes" ]; then
        log "Eliminando volúmenes EBS..."
        for volume in $volumes; do
            local state=$(aws ec2 describe-volumes --volume-ids $volume --query 'Volumes[0].State' --output text --region $AWS_REGION 2>/dev/null || echo "not-found")
            if [ "$state" = "available" ]; then
                aws ec2 delete-volume --volume-id $volume --region $AWS_REGION
                log "  - Volumen $volume eliminado"
            fi
        done
        log "✅ Volúmenes EBS procesados"
    fi
    
    # 5. Eliminar Security Groups
    local sgs=$(get_resources_by_tag "security-groups")
    if [ -n "$sgs" ]; then
        log "Eliminando Security Groups..."
        for sg in $sgs; do
            # Verificar que no sea el default
            local group_name=$(aws ec2 describe-security-groups --group-ids $sg --query 'SecurityGroups[0].GroupName' --output text --region $AWS_REGION)
            if [ "$group_name" != "default" ]; then
                aws ec2 delete-security-group --group-id $sg --region $AWS_REGION
                log "  - Security Group $sg eliminado"
            fi
        done
        log "✅ Security Groups eliminados"
    fi
    
    # 6. Eliminar Subnets
    local subnets=$(get_resources_by_tag "subnets")
    if [ -n "$subnets" ]; then
        log "Eliminando Subnets..."
        for subnet in $subnets; do
            aws ec2 delete-subnet --subnet-id $subnet --region $AWS_REGION
            log "  - Subnet $subnet eliminado"
        done
        log "✅ Subnets eliminados"
    fi
    
    # 7. Desasociar y eliminar Internet Gateways
    local igws=$(get_resources_by_tag "internet-gateways")
    if [ -n "$igws" ]; then
        log "Eliminando Internet Gateways..."
        for igw in $igws; do
            # Obtener VPC asociada
            local vpc=$(aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query 'InternetGateways[0].Attachments[0].VpcId' --output text --region $AWS_REGION)
            if [ "$vpc" != "None" ] && [ "$vpc" != "null" ]; then
                aws ec2 detach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc --region $AWS_REGION
            fi
            aws ec2 delete-internet-gateway --internet-gateway-id $igw --region $AWS_REGION
            log "  - Internet Gateway $igw eliminado"
        done
        log "✅ Internet Gateways eliminados"
    fi
    
    # 8. Eliminar Route Tables (no default)
    local route_tables=$(get_resources_by_tag "route-tables")
    if [ -n "$route_tables" ]; then
        log "Eliminando Route Tables..."
        for rt in $route_tables; do
            # Verificar que no sea la route table principal
            local main=$(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[0].Associations[?Main==`true`]' --output text --region $AWS_REGION)
            if [ -z "$main" ]; then
                aws ec2 delete-route-table --route-table-id $rt --region $AWS_REGION
                log "  - Route Table $rt eliminado"
            fi
        done
        log "✅ Route Tables eliminados"
    fi
    
    # 9. Eliminar VPCs
    local vpcs=$(get_resources_by_tag "vpcs")
    if [ -n "$vpcs" ]; then
        log "Eliminando VPCs..."
        for vpc in $vpcs; do
            aws ec2 delete-vpc --vpc-id $vpc --region $AWS_REGION
            log "  - VPC $vpc eliminado"
        done
        log "✅ VPCs eliminados"
    fi
    
    # 10. Eliminar Key Pairs
    local keys=$(get_resources_by_tag "key-pairs")
    if [ -n "$keys" ]; then
        log "Eliminando Key Pairs..."
        for key in $keys; do
            aws ec2 delete-key-pair --key-name $key --region $AWS_REGION
            log "  - Key Pair $key eliminado"
        done
        log "✅ Key Pairs eliminados"
    fi
}

# Función principal
main() {
    local force=false
    local dry_run=false
    
    # Procesar argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force|-f)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --project)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --region)
                AWS_REGION="$2"
                shift 2
                ;;
            -h|--help)
                echo "Script de limpieza completa de recursos AWS"
                echo ""
                echo "Uso: $0 [opciones]"
                echo ""
                echo "Opciones:"
                echo "  --force, -f       No pedir confirmación"
                echo "  --dry-run         Solo mostrar qué se eliminaría"
                echo "  --project NAME    Nombre del proyecto (default: helipistas-odoo)"
                echo "  --region REGION   Región AWS (default: us-east-1)"
                echo "  -h, --help        Mostrar esta ayuda"
                exit 0
                ;;
            *)
                error "Opción desconocida: $1"
                ;;
        esac
    done
    
    log "Iniciando limpieza de recursos AWS para proyecto: $PROJECT_NAME"
    log "Región: $AWS_REGION"
    
    check_aws_cli
    
    # Mostrar recursos encontrados
    if ! show_resources; then
        log "✅ No hay recursos que limpiar"
        exit 0
    fi
    
    # Estimar costos
    estimate_costs
    
    if [ "$dry_run" = true ]; then
        warn "🧪 Modo dry-run: No se eliminarán recursos"
        exit 0
    fi
    
    # Confirmación del usuario
    if [ "$force" = false ]; then
        echo ""
        warn "⚠️  ADVERTENCIA: Esta operación eliminará TODOS los recursos mostrados arriba"
        warn "⚠️  Esta acción NO se puede deshacer"
        echo ""
        read -p "¿Continuar con la eliminación? (escribe 'DELETE' para confirmar): " confirm
        
        if [ "$confirm" != "DELETE" ]; then
            log "Operación cancelada"
            exit 0
        fi
    fi
    
    # Intentar limpieza con Terraform primero
    if ! terraform_cleanup; then
        # Si falla, hacer limpieza manual
        manual_cleanup
    fi
    
    # Verificación final
    log "Verificando que todos los recursos fueron eliminados..."
    sleep 10
    
    if ! show_resources; then
        log "🎉 ¡Limpieza completada! Todos los recursos han sido eliminados"
    else
        warn "⚠️  Algunos recursos pueden no haberse eliminado completamente"
        warn "   Verifica manualmente en la consola de AWS"
    fi
}

# Ejecutar script
main "$@"
