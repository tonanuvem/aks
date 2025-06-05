#!/bin/bash

# ==============================================================================
# 1. DEFINIÇÃO DAS VARIÁVEIS
# (Ajuste apenas VALOR_SEGREDO, os outros nomes foram baseados em nossa conversa)
# ==============================================================================
NOME_GRUPO_RECURSOS="fiapaks"
NOME_KEY_VAULT="chavesecreta"
NOME_APP_CONFIG=${NOME_APP_CONFIG} # Nome do seu App Configuration Store
NOME_AKS="fiapaks"

NOME_SEGREDO_KV="segredo1"            # Nome do segredo DENTRO do Key Vault
VALOR_SEGREDO="Quem ganhar o KAHOOT da ultima aula vai ganhar um prêmio" # <<< AJUSTE ESTE VALOR PARA O SEU SEGREDO REAL
NOME_CHAVE_APPCONFIG_PARA_KVREF="segredo1" # Nome da chave no App Config que fará referência ao segredo do KV


# ==============================================================================
# 2. CRIAR O SEGREDO NO AZURE KEY VAULT
# ==============================================================================
echo "Criando o segredo '$NOME_SEGREDO_KV' no Key Vault '$NOME_KEY_VAULT'..."
az keyvault secret set \
  --vault-name $NOME_KEY_VAULT \
  --name $NOME_SEGREDO_KV \
  --value "$VALOR_SEGREDO"

echo "Segredo criado com sucesso."
echo "--------------------------------------------------"


# ==============================================================================
# 3. CRIAR A REFERÊNCIA DO KEY VAULT NO AZURE APP CONFIGURATION
# ==============================================================================
echo "Obtendo o URI do segredo para criar a referência..."
# Obtém o identificador (URI) completo do segredo que acabamos de criar.
SECRET_URI=$(az keyvault secret show --vault-name $NOME_KEY_VAULT --name $NOME_SEGREDO_KV --query id -o tsv)

echo "Criando a referência do Key Vault no App Configuration..."
# Cria a chave no App Configuration, apontando para o segredo no Key Vault.
az appconfig kv set-keyvault \
  --name $NOME_APP_CONFIG \
  --key $NOME_CHAVE_APPCONFIG_PARA_KVREF \
  --secret-identifier $SECRET_URI

echo "Referência do Key Vault criada com sucesso."
echo "--------------------------------------------------"


# ==============================================================================
# 4. CONFIGURAR AS PERMISSÕES (ATRIBUIÇÕES DE FUNÇÃO - RBAC)
# ==============================================================================
echo "Obtendo o Client ID da identidade do Kubelet do AKS..."
# Obtém o ID da identidade gerenciada do Kubelet do cluster AKS, que o provider usará.
ASSIGNEE_ID=$(az aks show --resource-group $NOME_GRUPO_RECURSOS --name $NOME_AKS --query identityProfile.kubeletidentity.clientId -o tsv)

echo "Atribuindo permissão de leitura do App Configuration para a identidade do AKS..."
# Permite que a identidade do AKS leia as chaves do App Configuration.
az role assignment create \
  --assignee $ASSIGNEE_ID \
  --role "App Configuration Data Reader" \
  --scope $(az appconfig show --name $NOME_APP_CONFIG --query id -o tsv)

echo "Atribuindo permissão de leitura de Segredos do Key Vault para a identidade do AKS..."
# Permite que a identidade do AKS leia os segredos do Key Vault.
az role assignment create \
  --assignee $ASSIGNEE_ID \
  --role "Key Vault Secrets User" \
  --scope $(az keyvault show --name $NOME_KEY_VAULT --query id -o tsv)

# --- Permissão Extra (Boa Prática) ---
echo "Habilitando a identidade gerenciada para o App Configuration Store..."
# Habilita uma identidade para o próprio serviço App Configuration.
az appconfig identity assign --name $NOME_APP_CONFIG --resource-group $NOME_GRUPO_RECURSOS -o none

echo "Atribuindo permissão para o App Configuration ler o Key Vault..."
# Permite que o serviço App Configuration (usado pelo Portal Azure) resolva a referência e mostre o valor.
APPCONFIG_IDENTITY_PRINCIPAL_ID=$(az appconfig identity show --name $NOME_APP_CONFIG --resource-group $NOME_GRUPO_RECURSOS --query principalId -o tsv)
az role assignment create \
    --assignee $APPCONFIG_IDENTITY_PRINCIPAL_ID \
    --role "Key Vault Secrets User" \
    --scope $(az keyvault show --name $NOME_KEY_VAULT --query id -o tsv)

echo "Todas as permissões foram configuradas com sucesso."
echo "--------------------------------------------------"
echo "Configuração via CLI concluída! ✅"
