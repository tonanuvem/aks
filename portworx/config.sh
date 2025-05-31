#!/bin/bash

# Verificar se está logado
if ! az account show > /dev/null 2>&1; then
  echo "Usuário não logado. Execute: az login --use-device-code"
  exit 1
fi

# LENDO CONFIGURAÇÕES NECESSÁRIAS
ROLENAME="portworx"
SID=$(az account show --query id --output tsv)
echo ""
echo "OK, Subscription ID configurado: $SID"
echo ""
echo "Clusters AKS existentes no ambiente:"
az aks list -o table
echo ""
read -p "Digite o nome do CLUSTER que será usado: " CLUSTER
read -p "Digite o nome do RESOURCE GROUP que será usado: " RG
echo ""
echo "Cluster selecionado: $CLUSTER no Resource Group: $RG"

# Criar role personalizada
az role definition create --role-definition "{
  \"Name\": \"$ROLENAME\",
  \"Description\": \"Role personalizada para Portworx\",
  \"AssignableScopes\": [\"/subscriptions/$SID\"],
  \"Actions\": [
    \"Microsoft.ContainerService/managedClusters/agentPools/read\",
    \"Microsoft.Compute/disks/delete\",
    \"Microsoft.Compute/disks/write\",
    \"Microsoft.Compute/disks/read\",
    \"Microsoft.Compute/virtualMachines/write\",
    \"Microsoft.Compute/virtualMachines/read\",
    \"Microsoft.Compute/virtualMachineScaleSets/virtualMachines/write\",
    \"Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read\"
  ],
  \"NotActions\": [],
  \"DataActions\": [],
  \"NotDataActions\": []
}"

# Obter node resource group
NODERG=$(az aks show -n $CLUSTER -g $RG --query nodeResourceGroup -o tsv)
echo "NodeResourceGroup: $NODERG"

# Criar service principal
RETORNO_JSON=$(az ad sp create-for-rbac --role="$ROLENAME" --scopes="/subscriptions/$SID/resourceGroups/$RG")
TENANT=$(echo "$RETORNO_JSON" | jq -r '.tenant')
APPID=$(echo "$RETORNO_JSON" | jq -r '.appId')
PASSWORD=$(echo "$RETORNO_JSON" | jq -r '.password')

echo ""
echo "Permissões configuradas:"
echo "TENANT: $TENANT"
echo "APPID : $APPID"
echo "PASSWORD: $PASSWORD"

# Criar secret para Portworx
kubectl create secret generic -n kube-system px-azure \
  --from-literal=AZURE_TENANT_ID=$TENANT \
  --from-literal=AZURE_CLIENT_ID=$APPID \
  --from-literal=AZURE_CLIENT_SECRET=$PASSWORD

# Instalar Portworx Operator
kubectl apply -f 'https://install.portworx.com/3.2?comp=pxoperator'

# Verificar instalação
kubectl get pods -A | grep portworx

# Aplicar StorageCluster (substitua com seu YAML correto)
kubectl apply -f k8s_aks_1_31_7.yaml

sleep 10

# Verificações finais
kubectl get pods -A -o wide | grep -e portworx -e px
kubectl get storagecluster -A
kubectl get storageclass -A
kubectl get pvc -A
