az group create --name akstraining-rg --location eastus
az aks create --resource-group akstraining-rg --name akstraining-cluster --node-count 2 --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group akstraining-rg --name akstraining-cluster --file ~/.kube/config-akstraining --overwrite-existing
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes
kubectl get namespaces
