#!/bin/bash

# ==============================================================================
# 1. DEFINIÇÃO DAS VARIÁVEIS
# ==============================================================================
# Variáveis que serão definidas dentro do script
NOME_GRUPO_RECURSOS="fiapaks"
NOME_AKS="fiapaks"
NOME_SEGREDO_KV="segredo1"
VALOR_SEGREDO="MeuValorSuperSecreto12345" # <<< AJUSTE ESTE VALOR SE NECESSÁRIO
NOME_CHAVE_APPCONFIG_PARA_KVREF="segredo1"

# O nome do Key Vault agora é derivado do nome do App Configuration
# ATENÇÃO: Este nome precisa ser único globalmente no Azure. Se este script falhar
# na criação do Key Vault, pode ser necessário adicionar um sufixo aleatório.
# Ex: NOME_KEY_VAULT="chavesecreta-${NOME_APP_CONFIG}-$(openssl rand -hex 3)"
NOME_KEY_VAULT="chavesecreta-${NOME_APP_CONFIG}"

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
echo "Criando o Azure App Configuration '$NOME_APP_CONFIG' (se não existir)..."
az appconfig create \
  --name $NOME_APP_CONFIG \
  --resource-group $NOME_GRUPO_RECURSOS \
  --location $LOCATION \
  --sku Free -o none

# ... (O restante do script continua igual) ...

# ==============================================================================
# 4. CRIAR O SEGREDO E A REFERÊNCIA
# ==============================================================================
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

echo "--------------------------------------------------"
# ==============================================================================
# 5. CONFIGURAR AS PERMISSÕES (RBAC)
# ==============================================================================
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
