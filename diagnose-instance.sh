#!/bin/bash

# Script para diagnosticar problemas con la instancia

INSTANCE_ID="i-020522ad2de8a19a7"

echo "=== INSTANCE DIAGNOSIS ==="
echo "Instance ID: $INSTANCE_ID"
echo ""

echo "=== INSTANCE STATUS ==="
aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].[State.Name,PublicIpAddress,PrivateIpAddress]' --output table
echo ""

echo "=== CONSOLE OUTPUT (Last 100 lines) ==="
aws ec2 get-console-output --instance-id $INSTANCE_ID --output text | tail -100
echo ""

echo "=== INSTANCE LOGS via CloudWatch (if available) ==="
# Intentar obtener logs si están configurados
aws logs describe-log-groups --log-group-name-prefix "/aws/ec2" 2>/dev/null || echo "No CloudWatch logs available"
