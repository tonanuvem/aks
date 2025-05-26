# Modulo 1:	Implementação de Helm Charts no AKS
#	Criação de um Helm Chart básico para uma aplicação de exemplo:
helm create fiap-chart

# Customização do Chart utilizando valores e templates, editar: 

  # > fiap-chart/values.yaml e 
  # > fiap-chart/templates/deployment.yaml
  
# Instalação do Chart no AKS:
helm install fiap-release ./fiap-chart

## SAÍDA DO COMANDO ANTERIOR ##
## NAME: fiap-release
# LAST DEPLOYED: Sun May 25 17:54:52 2025
# NAMESPACE: default
# STATUS: deployed
# REVISION: 1
# NOTES:
# 1. Get the application URL by running these commands:

IP=$(curl checkip.amazonaws.com)
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=fiap-chart,app.kubernetes.io/instance=fiap-release" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
echo "Visit http://$IP:8080 to use your application"
kubectl --namespace default port-forward $POD_NAME 8080:$CONTAINER_PORT


# Upgrade do Chart:
# Modificar o Chart (e.g., versão da imagem)

cp exemplo_values.yaml fiap-chart/values.yaml
helm upgrade fiap-release ./fiap-chart

#	Utilização de repositórios de Helm (públicos e privados):
helm repo add bitnami https://charts.bitnami.com/bitnami

# Prometheus
helm search repo bitnami/kube-prometheus
helm install prometheus bitnami/kube-prometheus
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090

# Grafana
IP=$(curl checkip.amazonaws.com)
HOST_GRAFANA="$IP" # Requisicao chega no Grafana 
# HOST_GRAFANA="grafana.$IP.sslip.io" # Requisicao tava chegando no code server
export HOST_GRAFANA

envsubst < grafana_values.yaml > grafana_values-final.yaml
helm install grafana bitnami/grafana -f grafana_values-final.yaml
# Obter a senha do admin do Grafana 
kubectl get secret --namespace default grafana-admin -o jsonpath="{.data.GF_SECURITY_ADMIN_PASSWORD}" | base64 --decode
echo
echo "Senha do Grafana = fiap"
kubectl port-forward svc/grafana 3000:3000


# Modulo 2.	Estratégias de CI/CD com Azure DevOps e AKS : FALHA NA PERMISSÃO DO AZURE STUDENTS.
# Conceitos de CI/CD: integração contínua, entrega contínua e deployment contínuo.
#	Integração do Azure DevOps com AKS: agentes, pipelines e conexões de serviço.
#	Automação do processo de build, teste e deployment de aplicações no AKS.
#	Integração com o Helm para automatizar a instalação de Charts (utilizando o HelmDeploy task).
# Implementação de testes automatizados no pipeline de CI/CD (adicionando tasks de teste, como CmdLine para executar testes unitários).

# > Criar um Projeto no Azure DevOps (via Portal): https://dev.azure.com
# > Criar nova Organização em https://aex.dev.azure.com/me?mkt=pt-BR
# > Create a project to get started em https://dev.azure.com/alunofiap/

az devops configure --defaults organization=https://dev.azure.com/SEU_ORG
az devops project create --name "fiap"
az repos create --name fiap --project "fiap"

# Criar Service Principal via CLI (usado para Service Connection) >> definir SUBSCRIPTION_ID
# az ad sp create-for-rbac --name "devops-aks-sp" --role contributor --scopes /subscriptions/<SUB_ID>/resourceGroups/<RESOURCE_GROUP>

az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o table
CLUSTER_INFO=$(az aks list --query "[0]" -o json)
CLUSTER_NAME=$(echo "$CLUSTER_INFO" | jq -r '.name')
RESOURCE_GROUP=$(echo "$CLUSTER_INFO" | jq -r '.resourceGroup')
echo "Cluster Name: $CLUSTER_NAME"
echo "Resource Group: $RESOURCE_GROUP"

SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo "Subscription ID ativa: $SUBSCRIPTION_ID"

az ad sp create-for-rbac --name $CLUSTER_NAME --role contributor  --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP --sdk-auth

# Criar Service Connection no Azure DevOps (semi-automático). A criação deve ser feita via portal Azure DevOps:
# Passos:
#    Acesse seu projeto no Azure DevOps.
#    Vá em Project Settings → Service connections.
#    No menu lateral esquerdo (dentro de Project Settings), clique em "Service connections" (embaixo de PIPELINE).
#    Clique em New service connection → escolha Azure Resource Manager.
#    Na próxima tela de configuração, escolher (STEP 1 : NEW AZURE SERVICE CONNECTION):
#        no Identity type   = APP REGISTRATION OR MANAGED IDENTITY (MANUAL) = 2o do Menu
#        no Credential      = SECRET
#        Em Enviroment deiar AZURE CLOUD e no Scope Level deixar "Subscription"
#    Na próxima configuração, escolher :
#        definir Subscription ID           = VALOR DO "subscriptionId" do comando anterior
#        definir Subscription name	       = FiapSubscription
#        definir Application (client) ID	 = VALOR DO "clientId" do comando anterior
#        definir Directory (tenant) ID     = VALOR DO TENANTID do comando anterior
#        deixar CREDENTIAL como Service principal key
#        Marque a opção: Grant access permission to all pipelines
#        definir Service Connection Name   = devops-aks
#        Clique em Verify and save         = VERIFICAR SE HÁ ERRO NA VALIDAÇÃO

#    Cole o JSON gerado pelo comando acima.
#    Dê um nome à conexão, por exemplo: conexao-azure.

# git clone https://dev.azure.com/ORGANIZACAO/PROJETO/_git/PROJETO
git clone https://dev.azure.com/alunofiap/fiap/_git/fiap
cd fiap

# Adicione seus arquivos (manifests, charts, código app), depois:
git add .
git commit -m "Commit inicial"
git push origin main

# Commitar o pipeline
git add azure-pipelines.yml
git commit -m "Pipeline CI/CD com Helm e AKS"
git push origin main

cat azure-pipelines.yml

# Modulo 3.	Gerenciamento de Configuração com Azure App Configuration
#	Introdução ao Azure App Configuration: conceitos e benefícios.
#	Armazenamento e gerenciamento centralizado de configurações de aplicações.
#	Integração do App Configuration com aplicações em execução no AKS.

az appconfig create --name nome-do-app-config --resource-group nome-do-grupo-de-recursos --location eastus

az appconfig kv set --name nome-do-app-config --key chave1 --value valor1
az appconfig kv set --name nome-do-app-config --key chave2 --value valor2 --content-type "application/json"

kubectl apply -f exemplo_deploy_ussando_configmap.yaml

#	Atualização dinâmica das configurações da aplicação sem necessidade de rebuild ou restart:
#	Demonstrar como uma alteração no App Configuration é refletida na aplicação.
#	Exemplo: Modifique um valor no App Configuration e observe a mudança na aplicação em execução no AKS.

az appconfig kv set --name nome-do-app-config --key chave1 --value mudou_valor1
az appconfig kv set --name nome-do-app-config --key chave2 --value mudou_valor2 --content-type "application/json"

## Modulo 4.	Práticas de Blue/Green Deployment e Canary Releases
#	Implementação de uma estratégia de Blue/Green Deployment para uma aplicação no AKS.

#	Deploy da versão "blue" da aplicação:
kubectl apply -f deployment-blue.yaml # YAML com a versão blue

#	Deploy da versão "green" da aplicação:
kubectl apply -f deployment-green.yaml # YAML com a versão green

#	Criação de um serviço para rotear o tráfego para a versão "blue":
kubectl apply -f service-blue.yaml

#	Modificação do serviço para rotear o tráfego para a versão "green":
kubectl apply -f service-green.yaml

#	Utilização de seletores para controlar o tráfego entre as versões da aplicação.
#	Implementação de uma estratégia de Canary Release para uma aplicação no AKS:
#	Deploy da versão canary da aplicação (com um número menor de réplicas):
kubectl apply -f deployment-canary.yaml

#	Utilização de um serviço com seletores para direcionar uma pequena porcentagem de tráfego 
# para a versão canary (e.g., utilizando um Ingress com pesos de tráfego 

#	Monitoramento e rollback 
kubectl rollout undo deployment/nome-do-deployment


## Modulo 5 : HPA


## Modulo 6.	Configuração de Node Pools e Node Selectors

#	Criação e gerenciamento de múltiplos Node Pools.

az aks nodepool add --cluster-name nome-do-cluster --resource-group nome-do-grupo-de-recursos --name pool-cpu --node-vm-size Standard_DS2_v2 --labels nodetype=cpu

az aks nodepool add --cluster-name nome-do-cluster --resource-group nome-do-grupo-de-recursos --name pool-gpu --node-vm-size Standard_NC6 --labels nodetype=gpu --taints sku=gpu:NoSchedule

#	Utilização de Node Selectors e Taints/Tolerations para agendar pods em Node Pools específicos.

echo "No exemplo acima, o pool pool-cpu tem o label nodetype=cpu, e o pool pool-gpu tem o label nodetype=gpu e o taint sku=gpu:NoSchedule."

#	Agendamento de diferentes aplicações em Node Pools específicos:

kubectl apply -f deploy_nodepool_CPU.yaml

kubectl apply -f deploy_nodepool_GPU.yaml

# Escalonamento de Node Pools:

az aks nodepool scale --cluster-name nome-do-cluster --resource-group nome-do-grupo-de-recursos --name pool-cpu --node-count 3




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
 
az aks nodepool add --cluster-name nome-do-cluster --resource-group nome-do-grupo-de-recursos --name spotpool --node-vm-size Standard_DS2_v2 --priority Spot --eviction-policy Delete

