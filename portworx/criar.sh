# Criar Cluster com --vm-node-size Standard_B2ms (2 cpu e 16 memoria):

az group create --name fiapaks-portworx --location centralus

# Se precisa estritamente de 2 vCPU, mas quer mais RAM, o Standard_E2s_v3 (2 vCPU, 16 GiB RAM) é uma boa opção.
az aks create --resource-group fiapaks-portworx --name fiapaks-portworx --node-count 2 --node-vm-size Standard_E2s_v3 --kubernetes-version 1.31.7 --enable-addons monitoring --generate-ssh-keys
#az aks create --resource-group fiapaks-portworx --name fiapaks-portworx --node-count 2 --node-vm-size Standard_B2ms --kubernetes-version 1.31.7 --enable-addons monitoring --generate-ssh-keys

az aks get-credentials --resource-group fiapaks-portworx --name fiapaks-portworx --file ~/.kube/config-fiapaks-portworx --overwrite-existing
export KUBECONFIG=~/.kube/config-fiapaks-portworx
kubectl get nodes
kubectl get namespaces
