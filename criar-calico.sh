# Criar o cluster 2 com CALICO
az group create --name akstraining-rg-2 --location westus
az aks create --resource-group akstraining-rg-2 --name akstraining-cluster-2 --network-plugin azure --network-policy calico --node-count 2 --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group akstraining-rg-2 --name akstraining-cluster-2 --file ~/.kube/config-akstraining  --overwrite-existing
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes
kubectl get namespaces
kubectl get pods -n calico-system
