#!/bin/bash

echo "🔍 Buscando todas as Azure Container Instances em sua conta..."

# Lista todas as Azure Container Instances (nome + resource group)
# O comando az container list busca na assinatura ativa por padrão.
# Se você quiser restringir a um grupo de recursos específico, adicione --resource-group SEU_GRUPO_DE_RECURSOS
CONTAINER_INSTANCES=$(az container list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)

if [ -z "$CONTAINER_INSTANCES" ]; then
    echo "✅ Nenhuma Azure Container Instance encontrada."
    exit 0
fi

echo "As seguintes Azure Container Instances serão excluídas:"
echo "$CONTAINER_INSTANCES"
echo "-----------------------------------------------------"
read -p "❓ Você tem certeza que deseja excluir TODAS essas Container Instances? (s/N): " CONFIRMATION

if [[ "$CONFIRMATION" != "s" && "$CONFIRMATION" != "S" ]]; then
    echo "❌ Operação cancelada pelo usuário."
    exit 1
fi

# Processa cada linha: nome e resource group
echo "$CONTAINER_INSTANCES" | while read -r CONTAINER_NAME RESOURCE_GROUP; do
    if [ -n "$CONTAINER_NAME" ] && [ -n "$RESOURCE_GROUP" ]; then # Garante que as variáveis não estão vazias
        echo "🗑️ Deletando Azure Container Instance: $CONTAINER_NAME (Resource Group: $RESOURCE_GROUP)..."
        az container delete --name "$CONTAINER_NAME" --resource-group "$RESOURCE_GROUP" --yes
        # O comando 'az container delete' não possui uma opção '--no-wait' explícita como 'az aks delete'.
        # A operação de exclusão é iniciada e o CLI geralmente aguarda a confirmação da API.
        # Se o comando acima falhar, você pode ver mensagens de erro aqui.
        if [ $? -eq 0 ]; then
            echo "✅ Azure Container Instance '$CONTAINER_NAME' marcada para exclusão."
        else
            echo "⚠️ Falha ao tentar excluir a Azure Container Instance '$CONTAINER_NAME' no grupo de recursos '$RESOURCE_GROUP'."
        fi
    fi
done

echo "🏁 Processo de exclusão das Azure Container Instances concluído."
