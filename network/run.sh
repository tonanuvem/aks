# Modulo 1: Preparação do Ambiente (30 minutos)

az group create --name akstraining-rg --location eastus
az aks create --resource-group akstraining-rg --name akstraining-cluster --node-count 2 --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group akstraining-rg --name akstraining-cluster --file ~/.kube/config-akstraining
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes

az aks show --resource-group akstraining-rg --name akstraining-cluster --query networkProfile.networkPlugin -o tsv



# Módulo 2: Arquitetura de Rede do AKS e Azure Virtual Networks (45 minutos)

kubectl create namespace demo-network
kubectl apply -f nginx-deploy.yaml

## (Opcional) Se o tempo permitir, instruir os participantes a criar outro cluster AKS (em outro grupo de recursos para evitar conflitos de nome) usando o Azure CNI (--network-plugin azure) e comparar a estrutura da VNet criada.

az group create --name akstraining-rg-2 --location westus
az aks create --resource-group akstraining-rg-2 --name akstraining-cluster-2 --network-plugin azure --network-policy calico --node-count 2 --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group akstraining-rg-2 --name akstraining-cluster-2 --file ~/.kube/config-akstraining
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes

az aks show --resource-group akstraining-rg-2 --name akstraining-cluster-2 --query networkProfile.networkPlugin -o tsv

# Módulo 3: Implementação de Network Policies no AKS (60 minutos)

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

kubectl exec -n namespace-b -it alpine-b -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx.namespace-a.svc.cluster.local"

# Depois: timeout

kubectl apply -f np-allow-only-same-namespace.yaml
kubectl get networkpolicy -A
kubectl describe networkpolicy allow-only-same-namespace -n namespace-a

kubectl exec -n namespace-b -it alpine-b -- sh -c "curl -v --connect-timeout 5 --max-time 10 nginx.namespace-a.svc.cluster.local"


# De novo: funciona

kubectl delete networkpolicy allow-only-same-namespace -n namespace-a

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

az aks delete --yes --name akstraining-rg --resource-group akstraining-rg && az group delete --yes --resource-group akstraining-rg

az aks delete --yes --name akstraining-rg-2 --resource-group akstraining-rg-2 && az group delete --yes --resource-group akstraining-rg-2
