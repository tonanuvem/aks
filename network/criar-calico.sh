# Criar o cluster 2 com CALICO
az group create --name akstraining-rg-calico --location westus
az aks create --resource-group akstraining-rg-calico --name akstraining-cluster-calico --network-plugin azure --network-policy calico --node-count 2 --node-vm-size Standard_B2s --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group akstraining-rg-calico --name akstraining-cluster-calico --file ~/.kube/config-akstraining  --overwrite-existing
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes
kubectl get namespaces
kubectl get pods -n calico-system
