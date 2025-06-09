#!/bin/bash

# ==============================================================================
# 1. DEFINIÇÃO DAS VARIÁVEIS
# ==============================================================================
# Variáveis que serão definidas dentro do script
NOME_GRUPO_RECURSOS="fiapaks"
NOME_AKS="fiapaks"
NOME_APP_CONFIG="${NOME_APP_CONFIG}"
NOME_SEGREDO_KV="segredo1"
VALOR_SEGREDO="Que tal se o Ganhador do Kahoot no último dia ganhar 2 chopps no almoço ?!" # <<< AJUSTE ESTE VALOR SE NECESSÁRIO
NOME_CHAVE_APPCONFIG_PARA_KVREF="segredo1"

# O nome do Key Vault terá um sufixo aleatório para garantir unicidade global
NOME_KEY_VAULT="${NOME_APP_CONFIG}"

# A localização será obtida dinamicamente do grupo de recursos
LOCATION=$(az group show --name $NOME_GRUPO_RECURSOS --query location -o tsv)


# ==============================================================================
# 2. VERIFICAÇÃO DAS VARIÁVEIS
# ==============================================================================
echo "Verificando se as variáveis foram definidas..."
if [ -z "$NOME_GRUPO_RECURSOS" ] || [ -z "$NOME_KEY_VAULT" ] || [ -z "$NOME_APP_CONFIG" ] || [ -z "$LOCATION" ]; then
    echo "ERRO: Uma ou mais variáveis essenciais não estão definidas. Verifique o template e as variáveis de ambiente exportadas."
    exit 1
fi
echo "Localização definida para: $LOCATION"
echo "Nome do Key Vault a ser criado: $NOME_KEY_VAULT"
echo "Variáveis definidas corretamente. Continuando..."
echo "--------------------------------------------------"


# ==============================================================================
# 3. PROVISIONAMENTO DOS RECURSOS PRINCIPAIS
# ==============================================================================
echo "Criando o Grupo de Recursos '$NOME_GRUPO_RECURSOS' (se não existir)..."
az group create --name $NOME_GRUPO_RECURSOS --location $LOCATION -o none

echo "--------------------------------------------------"
echo "Criando o Azure Key Vault '$NOME_KEY_VAULT'..."
az keyvault create \
  --name $NOME_KEY_VAULT \
  --resource-group $NOME_GRUPO_RECURSOS \
  --location $LOCATION \
  --enable-rbac-authorization

echo "--------------------------------------------------"
echo "Verificando/Criando o Azure App Configuration '$NOME_APP_CONFIG'..."
# Alterado para não falhar se já existir com um SKU diferente
az appconfig create \
  --name $NOME_APP_CONFIG \
  --resource-group $NOME_GRUPO_RECURSOS \
  --location $LOCATION \
  --sku Free -o none || echo "App Configuration '$NOME_APP_CONFIG' já existe ou ocorreu um erro não crítico."

# ==============================================================================
# 4. ATRIBUIR PERMISSÃO PARA O USUÁRIO ATUAL NO NOVO KEY VAULT (AJUSTE CRÍTICO)
# ==============================================================================
echo "Obtendo o ID do usuário logado..."
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)

echo "Atribuindo a função 'Key Vault Secrets Officer' para o usuário atual no novo Key Vault..."
az role assignment create \
  --assignee-object-id $CURRENT_USER_OBJECT_ID \
  --role "Key Vault Secrets Officer" \
  --scope $(az keyvault show --name $NOME_KEY_VAULT --query id -o tsv)

echo "Aguardando 30 segundos para a propagação da permissão RBAC..."
sleep 30

# ==============================================================================
# 5. CRIAR O SEGREDO E A REFERÊNCIA (AGORA COM PERMISSÃO)
# ==============================================================================
echo "--------------------------------------------------"
echo "Criando o segredo '$NOME_SEGREDO_KV' no Key Vault '$NOME_KEY_VAULT'..."
az keyvault secret set \
  --vault-name $NOME_KEY_VAULT \
  --name $NOME_SEGREDO_KV \
  --value "$VALOR_SEGREDO"

echo "--------------------------------------------------"
echo "Criando a referência do Key Vault no App Configuration..."
SECRET_URI=$(az keyvault secret show --vault-name $NOME_KEY_VAULT --name $NOME_SEGREDO_KV --query id -o tsv)
az appconfig kv set-keyvault \
  --name $NOME_APP_CONFIG \
  --key $NOME_CHAVE_APPCONFIG_PARA_KVREF \
  --secret-identifier "$SECRET_URI"

# ==============================================================================
# 6. CONFIGURAR AS PERMISSÕES PARA O AKS E APP CONFIG
# ==============================================================================
echo "--------------------------------------------------"
echo "Obtendo o Client ID da identidade do Kubelet do AKS..."
ASSIGNEE_ID=$(az aks show --resource-group $NOME_GRUPO_RECURSOS --name $NOME_AKS --query identityProfile.kubeletidentity.clientId -o tsv)

echo "Atribuindo permissão de leitura do App Configuration para a identidade do AKS..."
az role assignment create \
  --assignee $ASSIGNEE_ID \
  --role "App Configuration Data Reader" \
  --scope $(az appconfig show --name $NOME_APP_CONFIG --query id -o tsv)

echo "Atribuindo permissão de leitura de Segredos do Key Vault para a identidade do AKS..."
az role assignment create \
  --assignee $ASSIGNEE_ID \
  --role "Key Vault Secrets User" \
  --scope $(az keyvault show --name $NOME_KEY_VAULT --query id -o tsv)

echo "Habilitando a identidade gerenciada para o App Configuration Store..."
az appconfig identity assign --name $NOME_APP_CONFIG --resource-group $NOME_GRUPO_RECURSOS -o none

echo "Atribuindo permissão para o App Configuration ler o Key Vault..."
APPCONFIG_IDENTITY_PRINCIPAL_ID=$(az appconfig identity show --name $NOME_APP_CONFIG --resource-group $NOME_GRUPO_RECURSOS --query principalId -o tsv)
az role assignment create \
    --assignee $APPCONFIG_IDENTITY_PRINCIPAL_ID \
    --role "Key Vault Secrets User" \
    --scope $(az keyvault show --name $NOME_KEY_VAULT --query id -o tsv)

echo "--------------------------------------------------"
echo "Configuração completa concluída! ✅"
echo "O novo Key Vault criado se chama: $NOME_KEY_VAULT"
