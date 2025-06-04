#!/bin/bash

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!! 🚨 ALERTA MÁXIMO DE DESTRUIÇÃO DE DADOS 🚨 !!!"
echo "!!! Este script irá tentar remover TODAS as Azure File Shares E Storage Accounts !!!"
echo "!!! na assinatura ATIVA. Esta ação é IRREVERSÍVEL. !!!"
echo "!!! USANDO SOMENTE PARA ECONOMIA DOS CRÉDITOS. !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "Verifique sua assinatura atual:"
az account show
echo ""
echo "Este script requer 'jq' instalado para processar tags de armazenamento. Verifique se está instalado."
read -p "❓ Você tem CERTEZA ABSOLUTA e compreende as consequências de prosseguir? (Digite 'SIM, EU TENHO CERTEZA' para continuar): " GLOBAL_CONFIRMATION

if [[ "$GLOBAL_CONFIRMATION" != "SIM, EU TENHO CERTEZA" ]]; then
    echo "❌ Operação cancelada pelo usuário. Nenhuma alteração foi feita."
    exit 1
fi

echo ""
echo "🔍 Iniciando o processo para remover Azure File Shares e Storage Accounts..."
echo "   (O armazenamento do Azure Cloud Shell será preservado se identificado corretamente pela tag 'ms-resource-usage:azure-cloud-shell')"

# Etapa 1: Listar todas as Storage Accounts na assinatura, incluindo suas tags
echo "🔄 Listando todas as Storage Accounts e suas tags na assinatura (requer 'jq')..."
STORAGE_ACCOUNTS_JSON=$(az storage account list --query "[].{name:name, resourceGroup:resourceGroup, tags:tags}" -o json)

if [ -z "$STORAGE_ACCOUNTS_JSON" ] || [ "$STORAGE_ACCOUNTS_JSON" == "[]" ]; then
    echo "✅ Nenhuma Storage Account encontrada na assinatura."
    exit 0
fi

echo "🔎 Storage Accounts encontradas. O script solicitará confirmação antes de cada exclusão (exceto Cloud Shell Storage):"
# Para exibir a lista de forma mais amigável (opcional):
# echo "$STORAGE_ACCOUNTS_JSON" | jq -r '.[] | "  - Nome: \(.name), RG: \(.resourceGroup), Tags: \(.tags)"'
echo "--------------------------------------------------------------------------"

# Loop através de cada Storage Account usando jq para parsear o JSON
echo "$STORAGE_ACCOUNTS_JSON" | jq -c '.[]' | while IFS= read -r ACCOUNT_JSON_LINE; do
    ACCOUNT_NAME=$(echo "$ACCOUNT_JSON_LINE" | jq -r '.name')
    RG_NAME=$(echo "$ACCOUNT_JSON_LINE" | jq -r '.resourceGroup')
    # Extrai o valor da tag 'ms-resource-usage'. Se a tag não existir, jq retornará 'null'.
    MS_RESOURCE_USAGE_TAG=$(echo "$ACCOUNT_JSON_LINE" | jq -r '.tags."ms-resource-usage" // "null"')

    echo "➡️ Processando Storage Account: '$ACCOUNT_NAME' (Resource Group: '$RG_NAME')"

    # Verificar se é a Storage Account do Cloud Shell
    if [[ "$MS_RESOURCE_USAGE_TAG" == "azure-cloud-shell" ]]; then
        echo "  🛡️ Preservando Storage Account do Cloud Shell: '$ACCOUNT_NAME' (RG: '$RG_NAME'). Nenhuma ação será tomada nesta conta."
        echo "--------------------------------------------------------------------------"
        continue # Pula para a próxima conta de armazenamento
    fi

    # --- Sub-Etapa: Remover File Shares dentro da Storage Account (se não for Cloud Shell) ---
    echo "  🔄 Listando File Shares em '$ACCOUNT_NAME'..."
    FILE_SHARES_LIST=$(az storage share-rm list --resource-group "$RG_NAME" --storage-account-name "$ACCOUNT_NAME" --query "[].name" -o tsv 2>/dev/null)

    if [ -z "$FILE_SHARES_LIST" ]; then
        echo "  ✅ Nenhuma File Share encontrada em '$ACCOUNT_NAME'."
    else
        echo "  🔎 File Shares encontradas em '$ACCOUNT_NAME'. Solicitando confirmação para cada uma:"
        echo "$FILE_SHARES_LIST" | while IFS= read -r SHARE_NAME; do
             if [ -n "$SHARE_NAME" ]; then
                echo "" # Linha em branco para clareza
                read -p "    ❓ Deseja excluir a File Share: '$SHARE_NAME' da Storage Account '$ACCOUNT_NAME'? (s/N): " CONFIRM_SHARE_DELETE
                if [[ "$CONFIRM_SHARE_DELETE" == "s" || "$CONFIRM_SHARE_DELETE" == "S" ]]; then
                    echo "    🗑️ Tentando excluir File Share: '$SHARE_NAME' de '$ACCOUNT_NAME'..."
                    az storage share-rm delete --resource-group "$RG_NAME" --storage-account-name "$ACCOUNT_NAME" --name "$SHARE_NAME"
                    if [ $? -eq 0 ]; then
                        echo "    ✅ File Share '$SHARE_NAME' excluída com sucesso de '$ACCOUNT_NAME'."
                    else
                        echo "    ⚠️ Falha ao excluir File Share '$SHARE_NAME' de '$ACCOUNT_NAME', ou a exclusão foi cancelada."
                    fi
                else
                    echo "    ⏩ Exclusão da File Share '$SHARE_NAME' pulada pelo usuário."
                fi
            fi
        done
    fi
    echo "  🏁 Concluída a tentativa de exclusão de File Shares para '$ACCOUNT_NAME'."
    echo ""

    # --- Sub-Etapa: Remover a Storage Account (se não for Cloud Shell e após tentar remover as shares) ---
    read -p "  ❓ Deseja excluir a Storage Account: '$ACCOUNT_NAME' (RG: '$RG_NAME')? (Isto será tentado APÓS as file shares) (s/N): " CONFIRM_ACCOUNT_DELETE
    if [[ "$CONFIRM_ACCOUNT_DELETE" == "s" || "$CONFIRM_ACCOUNT_DELETE" == "S" ]]; then
        echo "  🗑️ Tentando excluir a Storage Account: '$ACCOUNT_NAME'..."
        az storage account delete --name "$ACCOUNT_NAME" --resource-group "$RG_NAME"
        if [ $? -eq 0 ]; then
            echo "  ✅ Storage Account '$ACCOUNT_NAME' excluída com sucesso."
        else
            echo "  ⚠️ Falha ao excluir a Storage Account '$ACCOUNT_NAME', ou a exclusão foi cancelada."
        fi
    else
        echo "  ⏩ Exclusão da Storage Account '$ACCOUNT_NAME' pulada pelo usuário."
    fi
    echo "--------------------------------------------------------------------------"
done

echo "🏁 Processo de tentativa de exclusão de File Shares e Storage Accounts concluído."
echo "📢 Lembre-se de verificar o portal do Azure para confirmar o status da exclusão e quaisquer falhas."
