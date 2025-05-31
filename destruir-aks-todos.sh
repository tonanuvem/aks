#!/bin/bash

echo "🔍 Buscando todos os clusters AKS em sua conta..."

# Lista todos os clusters AKS (nome + resource group)
CLUSTERS=$(az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)

if [ -z "$CLUSTERS" ]; then
    echo "✅ Nenhum cluster AKS encontrado."
    exit 0
fi

# Processa cada linha: nome e resource group
echo "$CLUSTERS" | while read -r CLUSTER_NAME RESOURCE_GROUP; do
    echo "⚠️ Deletando cluster AKS: $CLUSTER_NAME (Resource Group: $RESOURCE_GROUP)..."
    az aks delete --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --yes --no-wait
done

echo "✅ Todos os clusters AKS foram marcados para exclusão."
