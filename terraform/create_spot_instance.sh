#!/bin/bash
# Script para crear instancia spot con tipos alternativos

TERRAFORM_DIR="/Users/emiloalvarez/Work/PROYECTOS/HELIPISTAS/ODOO-17-2025/SERVER-SCRIPTS/terraform"
cd "$TERRAFORM_DIR"

# Lista de tipos de instancia en orden de preferencia (precio y disponibilidad)
INSTANCE_TYPES=("t3.medium" "t3a.medium" "t2.medium" "m5.large" "m5a.large" "m4.large" "t3.large" "t3a.large")

echo "=========================================="
echo "SCRIPT DE CREACIÓN DE INSTANCIA SPOT"
echo "=========================================="

for instance_type in "${INSTANCE_TYPES[@]}"; do
    echo ""
    echo "Intentando crear instancia spot con tipo: $instance_type"
    echo "----------------------------------------"
    
    # Actualizar el archivo tfvars con el tipo de instancia actual
    sed -i.bak "s/instance_type = \".*\"/instance_type = \"$instance_type\"/" terraform.tfvars
    
    # Intentar aplicar Terraform
    if terraform apply -var-file="terraform.tfvars" -auto-approve; then
        echo "✅ ¡Éxito! Instancia spot creada con tipo: $instance_type"
        echo "Verificando estado de la instancia..."
        
        # Esperar un poco y verificar que la instancia esté ejecutándose
        sleep 30
        INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null)
        
        if [ ! -z "$INSTANCE_ID" ]; then
            INSTANCE_STATE=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].State.Name' --output text)
            
            if [ "$INSTANCE_STATE" = "running" ]; then
                echo "✅ Instancia $INSTANCE_ID está ejecutándose correctamente"
                echo ""
                echo "=========================================="
                echo "INFORMACIÓN DE LA INSTANCIA CREADA:"
                echo "=========================================="
                terraform output
                echo "=========================================="
                exit 0
            else
                echo "⚠️  Instancia creada pero no está ejecutándose. Estado: $INSTANCE_STATE"
                echo "Destruyendo e intentando con siguiente tipo..."
                terraform destroy -auto-approve
            fi
        else
            echo "⚠️  No se pudo obtener el ID de la instancia"
            echo "Destruyendo e intentando con siguiente tipo..."
            terraform destroy -auto-approve
        fi
    else
        echo "❌ Fallo al crear instancia con tipo: $instance_type"
        echo "Motivos posibles:"
        echo "- No hay capacidad spot disponible para este tipo"
        echo "- Precio spot actual superior al máximo configurado"
        echo "- Límites de cuenta alcanzados"
        echo ""
        echo "Intentando con siguiente tipo de instancia..."
    fi
done

echo ""
echo "❌ ERROR: No se pudo crear ninguna instancia spot"
echo "Todos los tipos de instancia fallaron."
echo ""
echo "Soluciones posibles:"
echo "1. Aumentar el precio máximo spot en terraform.tfvars"
echo "2. Intentar en otra zona de disponibilidad"
echo "3. Usar instancia on-demand en lugar de spot"
echo "4. Verificar límites de cuenta AWS"

exit 1
