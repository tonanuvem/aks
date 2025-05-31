# https://docs.portworx.com/portworx-enterprise/platform/kubernetes/azure-aks/install/install-using-operator

# Verificar se está logado

if ! az account show > /dev/null 2>&1; then
  echo "Usuario não logado. Executar:         az login --use-device-code"
  exit 1
fi

#LENDO CONFIGURAÇÕES NECESSÁRIAS
ROLENAME="portworx"
SID=$(az account show --query id --output tsv)
echo ""
echo "OK, foi configurado Subscription ID: $SID"
echo ""
echo " Clusters AKS existentes no ambiente:"
echo ""
az aks list -o table
echo ""
echo "favor digitar o nome do CLUSTER que será usado:"
read CLUSTER
echo ""
echo "favor digitar o nome do RESOURCE GROUP que será usado:"
read RG
echo ""
echo ""
echo "OK, foi configurado o cluster Name: $CLUSTER que está no ResourceGroup: $RG"

# Create a custom role for Portworx. Enter the subscription ID using the subscription ID value you saved in step 1, also specify a role name:

az role definition create --role-definition '{
"Name": "$ROLENAME",
"Description": "",
"AssignableScopes": [
    "/subscriptions/$SID"
],
"Actions": [
    "Microsoft.ContainerService/managedClusters/agentPools/read",
    "Microsoft.Compute/disks/delete",
    "Microsoft.Compute/disks/write",
    "Microsoft.Compute/disks/read",
    "Microsoft.Compute/virtualMachines/write",
    "Microsoft.Compute/virtualMachines/read",
    "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/write",
    "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/read"
],
"NotActions": [],
"DataActions": [],
"NotDataActions": []
}'

# Create a Service Principal and secret in Azure AD

NODERG=$(az aks show -n $CLUSTER -g $RG | jq -r '.nodeResourceGroup')
echo "OK, foi configurado o NodeResourceGroup: $NODERG"

RETORNO_JSON=$(az ad sp create-for-rbac --role=$ROLENAME --scopes="/subscriptions/$ID/resourceGroups/$RG")
TENANT==$(echo "$RETORNO_JSON" | jq -r '.tenant')
APPID==$(echo "$RETORNO_JSON" | jq -r '.appId')
PASSWORD=$(echo "$RETORNO_JSON" | jq -r '.password')

echo ""
echo "OK, foi configurado a permissão TENANT: $TENANT ; APPID = $APPID ; PASSWORD = $PASSWORD"

kubectl create secret generic -n kube-system px-azure --from-literal=AZURE_TENANT_ID=$TENANT \
                                                      --from-literal=AZURE_CLIENT_ID=$APPID> \
                                                      --from-literal=AZURE_CLIENT_SECRET=$PASSWORD


kubectl apply -f 'https://install.portworx.com/3.2?comp=pxoperator'

kubectl get pods -A | grep "portworx"

kubectl apply -f k8s_aks_1_31_7.yaml

sleep 10

kubectl get pods -A -o wide | grep -e portworx -e px

kubectl get storagecluster -A

kubectl get storageclass -A

kubectl get pvc -A
