#!/bin/bash
# Script para verificar logs de la instancia EC2

INSTANCE_IP="54.228.16.152"
KEY_PATH="~/.ssh/LEULIT-WEBS.pem"

echo "=========================================="
echo "VERIFICANDO LOGS DE INSTANCIA EC2"
echo "IP: $INSTANCE_IP"
echo "=========================================="

# Función para ejecutar comandos remotos
run_remote() {
    ssh -i $KEY_PATH -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP "$1"
}

echo ""
echo "1. ESTADO GENERAL DE LA INSTANCIA:"
echo "-----------------------------------"
run_remote "uptime && free -h && df -h"

echo ""
echo "2. LOGS DE CLOUD-INIT:"
echo "----------------------"
run_remote "sudo tail -50 /var/log/cloud-init.log"

echo ""
echo "3. LOGS DE CLOUD-INIT OUTPUT:"
echo "-----------------------------"
run_remote "sudo tail -50 /var/log/cloud-init-output.log"

echo ""
echo "4. LOGS DE USER-DATA:"
echo "--------------------"
run_remote "sudo tail -50 /var/log/user-data.log"

echo ""
echo "5. LOGS ESPECÍFICOS DE HELIPISTAS:"
echo "----------------------------------"
run_remote "sudo tail -50 /var/log/helipistas-setup.log"

echo ""
echo "6. ESTADO DE MONTAJES:"
echo "---------------------"
run_remote "mount | grep efs && echo 'EFS montado' || echo 'EFS NO montado'"
run_remote "df -h | grep efs || echo 'No hay filesystem EFS montado'"

echo ""
echo "7. SERVICIOS DOCKER:"
echo "-------------------"
run_remote "sudo systemctl status docker || echo 'Docker no iniciado'"
run_remote "sudo docker ps || echo 'No hay contenedores'"

echo ""
echo "8. PROCESOS RELACIONADOS:"
echo "------------------------"
run_remote "ps aux | grep -E '(docker|mount|efs)' | grep -v grep"

echo ""
echo "9. LOGS DE SISTEMA (ÚLTIMAS 20 LÍNEAS):"
echo "---------------------------------------"
run_remote "sudo journalctl -n 20 --no-pager"

echo ""
echo "10. VERIFICAR SI EL SETUP ESTÁ COMPLETO:"
echo "----------------------------------------"
run_remote "sudo ls -la /efs/ 2>/dev/null || echo 'Directorio /efs no accesible'"
run_remote "sudo ls -la /efs/HELIPISTAS-ODOO-17/ 2>/dev/null || echo 'Proyecto no encontrado en EFS'"

echo ""
echo "=========================================="
echo "VERIFICACIÓN COMPLETADA"
echo "=========================================="
