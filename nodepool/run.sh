##################################################################
## Modulo 6.	Configuração de Node Pools e Node Selectors
##################################################################
#	Criação e gerenciamento de múltiplos Node Pools.

az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o table
CLUSTER_INFO=$(az aks list --query "[0]" -o json)
CLUSTER_NAME=$(echo "$CLUSTER_INFO" | jq -r '.name')
RESOURCE_GROUP=$(echo "$CLUSTER_INFO" | jq -r '.resourceGroup')
echo "Cluster Name: $CLUSTER_NAME"
echo "Resource Group: $RESOURCE_GROUP"

NOME_APP_CONFIG="fiap-app-config"
echo $NOME_APP_CONFIG

# Criar diferentes nodepools no AKS (Azure Kubernetes Service) é uma estratégia poderosa para gerenciar diferentes tipos de cargas de trabalho
# Ex 1. Se você tem workloads com diferentes requisitos (CPU, memória, GPU, SO, etc.), separe-os em nodepools distintos: ex: APP_WEB x BD x IA x Jobs
# Ex 2. Você pode ter containers que rodam em Linux e outros que precisam de Windows (.NET FULL)
# Ex 3. Times ou ambientes (dev, staging, prod) podem usar nodepools separados (ex: nodepool-dev, nodepool-stg, nodepool-prod) com quotas, tolerâncias, affinities e RBAC específicas
# Ex 4. Nodepools podem ter escalonamento diferente (Prod com min=3 e max=10) x (Dev com min=0 e max=2)

az aks nodepool list --resource-group $RESOURCE_GROUP  --cluster-name $CLUSTER_NAME  -o table

# OBS: Não é possível "adicionar" Windows a um cluster existente depois de criado, pois o suporte a Windows precisa ser configurado desde o início.
az aks show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query windowsProfile

az aks nodepool add --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --name wincpu --os-type Windows --node-vm-size Standard_B2s --node-count 1 --labels nodetype=wincpu

az aks nodepool add --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --name linuxgpu --os-type Linux --node-vm-size Standard_NC4as_T4_v3 --node-count 1 --labels nodetype=linuxgpu --node-taints sku=gpu:NoSchedule

az aks nodepool list --resource-group $RESOURCE_GROUP  --cluster-name $CLUSTER_NAME  -o table

#	Utilização de Node Selectors e Taints/Tolerations para agendar pods em Node Pools específicos.

echo "No exemplo acima, o pool pool-cpu tem o label nodetype=cpu, e o pool pool-gpu tem o label nodetype=gpu e o taint sku=gpu:NoSchedule."

#	Agendamento de diferentes aplicações em Node Pools específicos:
# Como usar esses node pools
# No seu deployment Kubernetes, especifique no manifest qual node pool quer usar via nodeSelector:

kubectl apply -f deploy_svc_nodepool_winCPU.yaml

kubectl apply -f deploy_svc_nodepool_linuxGPU.yaml

# Escalonamento de Node Pools:

az aks nodepool scale --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --name pool-cpu --node-count 2


##################################################################

## Modulo 7.	Gerenciamento de Custos e Otimização de Recursos
#	Visão geral dos custos do AKS.
#	Estratégias para otimizar o uso de recursos e reduzir custos.
#	Utilização de Spot VMs e Reserved Instances.
#	Monitoramento e análise de custos no Azure.
#	Implementação de quotas e limites de recursos no AKS (exemplos de YAML):

kubectl apply -f custo_resource_quota.yaml

kubectl apply -f custo_limit_range.yaml

#	Utilização de Spot VMs para executar cargas de trabalho tolerantes a falhas:
#	Criação de um Node Pool com Spot VMs.
 
az aks nodepool add --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --name pool-spot --node-vm-size Standard_DS2_v2 --priority Spot --eviction-policy Delete
