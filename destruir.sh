#!/bin/bash

# Nome base do resource group
PREFIX="akstraining-rg"

# Lista todos os resource groups que começam com o prefixo
echo "🔍 Buscando resource groups que começam com '$PREFIX'..."
RESOURCE_GROUPS=$(az group list --query "[?starts_with(name, '$PREFIX')].name" -o tsv)

for RG in $RESOURCE_GROUPS; do
    echo "📦 Processando resource group: $RG"

    # Lista os clusters AKS dentro do resource group
    CLUSTERS=$(az aks list --resource-group "$RG" --query "[].name" -o tsv)

    for CLUSTER in $CLUSTERS; do
        echo "⚠️ Deletando cluster AKS: $CLUSTER (Resource Group: $RG)..."
        az aks delete --name "$CLUSTER" --resource-group "$RG" --yes --no-wait
    done
done

echo "✅ Todos os clusters iniciando com '$PREFIX' estão em processo de exclusão."
