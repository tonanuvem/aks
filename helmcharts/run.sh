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
helm search repo bitnami/nginx
helm install my-bitnami-nginx bitnami/nginx

# Modulo 2.	Estratégias de CI/CD com Azure DevOps e AKS
# Conceitos de CI/CD: integração contínua, entrega contínua e deployment contínuo.
#	Integração do Azure DevOps com AKS: agentes, pipelines e conexões de serviço.
#	Automação do processo de build, teste e deployment de aplicações no AKS.
#	Integração com o Helm para automatizar a instalação de Charts (utilizando o HelmDeploy task).
# Implementação de testes automatizados no pipeline de CI/CD (adicionando tasks de teste, como CmdLine para executar testes unitários).

cat k8s_cicd.yaml

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

