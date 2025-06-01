# Criar Cluster com --vm-node-size Standard_B2ms (2 cpu e 16 memoria):

az group create --name fiapaks-portworx --location centralus

az aks create --resource-grouop fiapaks-portworx-rg --name fiapaks-portworx --node-count 2 --node-vm-size Standard_B2ms --kubernetes-version 1.31.7 --enable-addons-monitttorinig --generate-ssh-keys

