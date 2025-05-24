# Modulo 1: Preparação do Ambiente (10 minutos) : FAZER EM DUPLAS, 
# 1o aluno cria o cluster 1 sem nenhum parametro de rede.
# 2o aluno cria o cluster 2 com parametros:  --network-plugin azure --network-policy calico 

az login --use-device-code
# az account set --subscription "Azure for Students"

az group create --name akstraining-rg --location eastus
az aks create --resource-group akstraining-rg --name akstraining-cluster --node-count 2 --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group akstraining-rg --name akstraining-cluster --file ~/.kube/config-akstraining --overwrite-existing
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes
kubectl get namespaces

az aks show --resource-group akstraining-rg --name akstraining-cluster --query networkProfile.networkPlugin -o tsv
# resultado esperado = mostra CNI da azure


# Módulo 2: Arquitetura de Rede do AKS e Azure Virtual Networks (15 minutos)

kubectl create namespace demo-network
kubectl apply -f nginx-deploy.yaml

# Módulo 3: Implementação de Network Policies no AKS (20 minutos)

kubectl create namespace namespace-a
kubectl get ns namespace-a --show-labels
kubectl apply -f nginx-deploy-a.yaml -n namespace-a
kubectl apply -f nginx-service-a.yaml
kubectl apply -f pod-alpine-a.yaml -n namespace-a

kubectl create namespace namespace-b
kubectl get ns namespace-b --show-labels
kubectl apply -f pod-alpine-b.yaml -n namespace-b


# ✅ Resultado esperado:
#    Antes de aplicar a NetworkPolicy → o curl deve funcionar e retornar a página padrão do Nginx.
#    Depois de aplicar a NetworkPolicy → o curl deve falhar (timeout), pois o tráfego de namespace-b para namespace-a está bloqueado.
#    Na prática, a configuração não funcionooou pq a driver de rede nao suporta a configuracao


# Antes :funciona

kubectl exec -n namespace-b -it pod-alpine-b -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx-service-a.namespace-a.svc.cluster.local"

# Depois: deveria dar timeout, mas a configuração não funcionooou pq o driver de rede nao suporta NetworkPolicies

kubectl apply -f np-allow-only-same-namespace-a.yaml
kubectl get networkpolicy -A
kubectl describe networkpolicy allow-only-same-namespace -n namespace-a

kubectl exec -n namespace-a -it pod-alpine-a -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx-service-a.namespace-a.svc.cluster.local"

kubectl exec -n namespace-b -it pod-alpine-b -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx-service-a.namespace-a.svc.cluster.local"

# Tanto o comando executado pelo namespace-b, como pelo namespace-a, esão funcionando; embora só o A deveria funcionar

##############

## (Opcional) Se o tempo permitir, instruir os participantes a criar outro cluster AKS (em outro grupo de recursos para evitar conflitos de nome) usando o Azure CNI (--network-plugin azure) e comparar a estrutura da VNet criada.

# Deletar o cluster 1
az aks delete --yes --name akstraining-rg --resource-group akstraining-rg && az group delete --yes --resource-group akstraining-rg

# Criar o cluster 2
az group create --name akstraining-rg-2 --location westus
az aks create --resource-group akstraining-rg-2 --name akstraining-cluster-2 --network-plugin azure --network-policy calico --node-count 2 --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group akstraining-rg-2 --name akstraining-cluster-2 --file ~/.kube/config-akstraining  --overwrite-existing
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes
kubectl get namespaces
kubectl get pods -n calico-system

az aks show --resource-group akstraining-rg-2 --name akstraining-cluster-2 --query networkProfile.networkPlugin -o tsv


# Vamos criar o Namespace C:

kubectl create namespace namespace-c
kubectl get ns namespace-c --show-labels
kubectl apply -f pod-alpine-c.yaml -n namespace-c

kubectl exec -n namespace-c -it pod-alpine-c -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx.namespace-a.svc.cluster.local"

# Aplicar Network Policies permitindo o pod com label

kubectl apply -f np-allow-from-pod-with-label.yaml
kubectl get networkpolicies -n namespace-a
kubectl describe networkpolicies allow-from-pod-with-label -n namespace-a

kubectl get pods -n namespace-c --show-labels
kubectl label pod pod-alpine-c -n namespace-c acesso=permitir

kubectl exec -n namespace-c -it pod-alpine-c -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx.namespace-a.svc.cluster.local"

# De novo: funciona

kubectl delete networkpolicy allow-only-same-namespace-a -n namespace-a
kubectl get networkpolicies -A

kubectl exec -n namespace-b -it alpine-b -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx.namespace-a.svc.cluster.local"


# Se, mesmo após aplicar a NetworkPolicy corretamente, o pod Alpine em namespace-b ainda consegue acessar o Nginx em namespace-a, 
# é bem provável que o seu cluster não tenha um CNI (Container Network Interface) compatível com NetworkPolicy instalado ou ativado.
# ✅ Passos para diagnosticar e resolver:
# 1. 🧠 Você está usando AKS (Azure Kubernetes Service)?#
# Se sim, AKS suporta Network Policies, mas somente se você escolher o plugin de rede correto ao criar o cluster.#
#    O suporte à NetworkPolicy exige que você tenha usado "Azure CNI" com suporte a kubenet ou Calico.#

# 👉 Verifique se NetworkPolicy está funcionando:#
# Execute:#

#kubectl get pods -A -o wide | grep calico
kubectl get pods -n calico-system

#Se você não vir pods do Calico ou algo similar (como azure-npm), provavelmente o suporte a políticas de rede não está habilitado.

#Verificando o suporte a NetworkPolicy

#Agora, veja qual plugin de política de rede está ativado:

# az aks show --resource-group <nome-do-resource-group> --name <nome-do-cluster> --query networkProfile.networkPolicy -o tsv
az aks show --resource-group akstraining-rg-2 --name akstraining-cluster-2 --query networkProfile.networkPlugin -o tsv

# Possíveis respostas:

#    calico → ✅ Suporta NetworkPolicy

#    azure → ✅ Suporta NetworkPolicy (com limitações)

#    null ou vazio → ❌ Não há suporte a NetworkPolicy



az aks delete --yes --name akstraining-rg-2 --resource-group akstraining-rg-2 && az group delete --yes --resource-group akstraining-rg-2
