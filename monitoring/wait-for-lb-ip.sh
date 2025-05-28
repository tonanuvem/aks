#!/bin/bash

# Nome do serviço e namespace
SERVICE_NAME=$1
NAMESPACE=${2:-default}  # padrão é 'default' se não for passado

if [ -z "$SERVICE_NAME" ]; then
  echo "Uso: $0 <nome-do-serviço> [namespace]"
  exit 1
fi

echo -n "Aguardando IP externo para o serviço '$SERVICE_NAME' no namespace '$NAMESPACE'"

# Espera até que o IP externo seja atribuído
while true; do
  EXTERNAL_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  
  if [ -n "$EXTERNAL_IP" ]; then
    echo -e "\n✅ IP externo disponível: $EXTERNAL_IP"
    break
  fi

  echo -n "."
  sleep 1
done
