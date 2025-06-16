#!/bin/bash

echo "=== ANÁLISE DE RECURSOS POR NÓ ==="
echo

for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    echo "----------------------------------------"
    echo "Nó: $node"
    echo "----------------------------------------"
    echo ""
    echo "Recursos Alocáveis:"
    kubectl get node $node -o jsonpath='{.status.allocatable.cpu}{"m CPU, "}{.status.allocatable.memory}{" Memory"}'
    echo

    echo ""
    echo "Pods neste nó:"
    kubectl get pods --all-namespaces --field-selector spec.nodeName=$node -o custom-columns="NAMESPACE:.metadata.namespace,NAME:.metadata.name,CPU-REQ:.spec.containers[*].resources.requests.cpu,MEM-REQ:.spec.containers[*].resources.requests.memory" --no-headers

    echo ""
    echo "Total reservado neste nó:"
    kubectl describe node $node | grep -A 4 "Allocated resources"
    echo
    echo ""
done
