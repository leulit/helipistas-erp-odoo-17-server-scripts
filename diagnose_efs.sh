#!/bin/bash

echo "=== DIAGNÓSTICO EFS ==="
echo "Fecha: $(date)"
echo

echo "1. Verificando variables de entorno:"
echo "EFS_ID: ${EFS_ID}"
echo

echo "2. Verificando logs de user-data:"
if [ -f /var/log/user-data.log ]; then
    echo "Log existe, últimas 50 líneas:"
    tail -50 /var/log/user-data.log
else
    echo "Log de user-data no encontrado"
fi
echo

echo "3. Verificando si amazon-efs-utils está instalado:"
yum list installed | grep amazon-efs-utils || echo "amazon-efs-utils NO instalado"
echo

echo "4. Verificando conectividad al EFS:"
ping -c 2 fs-ec7152d9.efs.eu-west-1b.amazonaws.com || echo "No hay conectividad al EFS"
echo

echo "5. Verificando /etc/fstab:"
cat /etc/fstab | grep efs || echo "No hay entradas EFS en fstab"
echo

echo "6. Intentando montar manualmente:"
mkdir -p /efs
echo "fs-ec7152d9.efs.eu-west-1b.amazonaws.com:/ /efs efs defaults,_netdev,tls" >> /etc/fstab
mount -t efs fs-ec7152d9.efs.eu-west-1b.amazonaws.com:/ /efs
echo "Estado del mount: $?"
df -h | grep efs || echo "EFS no montado"
echo

echo "7. Verificando directorios:"
ls -la /efs/ || echo "No se puede listar /efs"
ls -la /efs/ODOO-ERP-HELIPISTAS/ || echo "No se puede listar /efs/ODOO-ERP-HELIPISTAS/"
