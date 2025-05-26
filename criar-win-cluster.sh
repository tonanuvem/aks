az group create --name akstraining-rg-win --location centralindia

# Verificar todas as regiões disponíveis na Azure:
#az account list-locations -o table

# Usar uma versão AKS comum (não-LTS) : escolha a versão mais alta não-LTS (ex: primeira linha do comando abaixo)
#az aks get-versions --location centralindia --output table

az aks create \
  --resource-group akstraining-rg-win \
  --name akstraining-cluster-win \
  --node-count 1 \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --windows-admin-username fiap \
  --windows-admin-password "S3nhaForteAqui123!" \
  --network-plugin azure --network-policy calico \
  --kubernetes-version 1.33.0 \
  --vm-set-type VirtualMachineScaleSets

az aks get-credentials --resource-group akstraining-rg-win --name akstraining-cluster-win --file ~/.kube/config-akstraining  --overwrite-existing
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes
kubectl get namespaces
kubectl get pods -n calico-system
