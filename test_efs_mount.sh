#!/bin/bash

echo "=== PRUEBA DE MONTAJE EFS ==="
echo "Fecha: $(date)"

# Variables del EFS
EFS_ID="fs-ec7152d9"
REGION="eu-west-1"

echo "EFS_ID: $EFS_ID"
echo "Region: $REGION"

# Crear directorio si no existe
mkdir -p /efs

# Limpiar /etc/fstab de entradas EFS anteriores
grep -v "efs" /etc/fstab > /tmp/fstab_clean
mv /tmp/fstab_clean /etc/fstab

# Desmontar si está montado
umount /efs 2>/dev/null || true

echo "1. Probando conectividad al EFS..."
EFS_DNS="$EFS_ID.efs.$REGION.amazonaws.com"
echo "DNS del EFS: $EFS_DNS"

# Probar conectividad
if nslookup $EFS_DNS; then
    echo "✓ DNS resuelve correctamente"
else
    echo "✗ Error de DNS"
    exit 1
fi

echo "2. Intentando montar EFS..."
echo "$EFS_DNS:/ /efs efs defaults,_netdev,tls" >> /etc/fstab

if mount -t efs $EFS_DNS:/ /efs; then
    echo "✓ EFS montado exitosamente"
    
    echo "3. Verificando montaje..."
    df -h | grep efs
    
    echo "4. Listando contenido del EFS..."
    ls -la /efs/
    
    if [ -d "/efs/ODOO-ERP-HELIPISTAS" ]; then
        echo "✓ Directorio ODOO-ERP-HELIPISTAS encontrado"
        ls -la /efs/ODOO-ERP-HELIPISTAS/
    else
        echo "✗ Directorio ODOO-ERP-HELIPISTAS no encontrado"
    fi
    
    echo "5. Creando directorio de prueba..."
    mkdir -p /efs/ODOO-ERP-HELIPISTAS/HLP-ERP-ODOO-17/test
    echo "test file" > /efs/ODOO-ERP-HELIPISTAS/HLP-ERP-ODOO-17/test/test.txt
    
    if [ -f "/efs/ODOO-ERP-HELIPISTAS/HLP-ERP-ODOO-17/test/test.txt" ]; then
        echo "✓ Escritura en EFS funciona correctamente"
        cat /efs/ODOO-ERP-HELIPISTAS/HLP-ERP-ODOO-17/test/test.txt
    else
        echo "✗ Error al escribir en EFS"
    fi
    
else
    echo "✗ Error al montar EFS"
    exit 1
fi

echo "=== MONTAJE EFS EXITOSO ==="
