az aks list --query "[].{name:name, resourceGroup:resourceGroup}" -o table
CLUSTER_INFO=$(az aks list --query "[0]" -o json)
CLUSTER_NAME=$(echo "$CLUSTER_INFO" | jq -r '.name')
RESOURCE_GROUP=$(echo "$CLUSTER_INFO" | jq -r '.resourceGroup')
echo "Cluster Name: $CLUSTER_NAME"
echo "Resource Group: $RESOURCE_GROUP"
