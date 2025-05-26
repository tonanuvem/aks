az group create --name akstraining-rg-win --location westus

az aks create \
  --resource-group akstraining-rg-win \
  --name akstraining-cluster-win \
  --node-count 1 \
  --enable-addons monitoring \
  --generate-ssh-keys \
  --windows-admin-username fiap \
  --windows-admin-password "S3nhaForteAqui123!" \
  --enable-windows \
  --kubernetes-version 1.29.2 \
  --vm-set-type VirtualMachineScaleSets

az aks get-credentials --resource-group akstraining-rg-win --name akstraining-cluster-win --file ~/.kube/config-akstraining  --overwrite-existing
export KUBECONFIG=~/.kube/config-akstraining
kubectl get nodes
kubectl get namespaces
kubectl get pods -n kube-system
