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
read -p "❓ Você tem CERTEZA ABSOLUTA e compreende as consequências de prosseguir com a varredura e possíveis exclusões? (Digite 'SIM, EU TENHO CERTEZA' para continuar): " GLOBAL_CONFIRMATION

if [[ "$GLOBAL_CONFIRMATION" != "SIM, EU TENHO CERTEZA" ]]; then
    echo "❌ Operação cancelada pelo usuário. Nenhuma alteração foi feita."
    exit 1
fi

echo ""
echo "🔍 Iniciando o processo para remover Azure File Shares e Storage Accounts..."

# Etapa 1: Listar todas as Storage Accounts na assinatura
echo "🔄 Listando todas as Storage Accounts na assinatura..."
STORAGE_ACCOUNTS_LIST=$(az storage account list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)

if [ -z "$STORAGE_ACCOUNTS_LIST" ]; then
    echo "✅ Nenhuma Storage Account encontrada na assinatura."
    exit 0
fi

echo "🔎 Storage Accounts encontradas. O script solicitará confirmação antes de cada exclusão:"
echo "$STORAGE_ACCOUNTS_LIST"
echo "--------------------------------------------------------------------------"

# Loop através de cada Storage Account
echo "$STORAGE_ACCOUNTS_LIST" | while IFS=$'\t' read -r ACCOUNT_NAME RG_NAME; do
    if [ -n "$ACCOUNT_NAME" ] && [ -n "$RG_NAME" ]; then
        echo "➡️ Processando Storage Account: '$ACCOUNT_NAME' (Resource Group: '$RG_NAME')"

        # --- Sub-Etapa: Remover File Shares dentro da Storage Account ---
        echo "  🔄 Listando File Shares em '$ACCOUNT_NAME'..."
        FILE_SHARES_LIST=$(az storage share-rm list --resource-group "$RG_NAME" --storage-account-name "$ACCOUNT_NAME" --query "[].name" -o tsv)

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
                        # A flag --yes foi removida para que o próprio comando 'az' possa pedir confirmação se necessário,
                        # ou para permitir que o usuário cancele no prompt do 'az'.
                        # Para excluir shares com snapshots, pode ser necessário --include snapshots ou --include all
                        az storage share-rm delete --resource-group "$RG_NAME" --storage-account-name "$ACCOUNT_NAME" --name "$SHARE_NAME"
                        if [ $? -eq 0 ]; then
                            echo "    ✅ File Share '$SHARE_NAME' excluída com sucesso de '$ACCOUNT_NAME'."
                        else
                            echo "    ⚠️ Falha ao excluir File Share '$SHARE_NAME' de '$ACCOUNT_NAME', ou a exclusão foi cancelada. Pode ser devido a snapshots, bloqueios ou outras retenções. Verifique os logs ou o portal."
                        fi
                    else
                        echo "    ⏩ Exclusão da File Share '$SHARE_NAME' pulada pelo usuário."
                    fi
                fi
            done
        fi
        echo "  🏁 Concluída a tentativa de exclusão de File Shares para '$ACCOUNT_NAME'."
        echo "" # Linha em branco para separação

        # --- Sub-Etapa: Remover a Storage Account (após tentar remover as shares) ---
        read -p "  ❓ Deseja excluir a Storage Account: '$ACCOUNT_NAME' (RG: '$RG_NAME')? (Isto será tentado APÓS as file shares) (s/N): " CONFIRM_ACCOUNT_DELETE
        if [[ "$CONFIRM_ACCOUNT_DELETE" == "s" || "$CONFIRM_ACCOUNT_DELETE" == "S" ]]; then
            echo "  🗑️ Tentando excluir a Storage Account: '$ACCOUNT_NAME'..."
            # A flag --yes foi removida.
            az storage account delete --name "$ACCOUNT_NAME" --resource-group "$RG_NAME"
            if [ $? -eq 0 ]; then
                echo "  ✅ Storage Account '$ACCOUNT_NAME' excluída com sucesso."
            else
                echo "  ⚠️ Falha ao excluir a Storage Account '$ACCOUNT_NAME', ou a exclusão foi cancelada. Verifique se todos os recursos (blob containers, tabelas, filas, bloqueios) foram removidos."
            fi
        else
            echo "  ⏩ Exclusão da Storage Account '$ACCOUNT_NAME' pulada pelo usuário."
        fi
        echo "--------------------------------------------------------------------------"
    else
        echo "⏭️ Linha de Storage Account inválida ou vazia encontrada, pulando."
        echo "--------------------------------------------------------------------------"
    fi
done < <(echo "$STORAGE_ACCOUNTS_LIST")

echo "🏁 Processo de tentativa de exclusão de File Shares e Storage Accounts concluído."
echo "📢 Lembre-se de verificar o portal do Azure para confirmar o status da exclusão e quaisquer falhas."
