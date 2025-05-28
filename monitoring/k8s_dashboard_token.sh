#!/bin/bash
#export COLOR_RESET='\e[0m'
#export COLOR_LIGHT_GREEN='\e[0;49;32m' 

#export INGRESS_HOST=$(curl -s checkip.amazonaws.com)

wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.6.1/aio/deploy/recommended.yaml

# Ajustar para acessar de maneira insegura (somente para LAB):
#sed -i 's|            - --auto-generate-certificates|            - --enable-skip-login\n            - --disable-settings-authorizer\n            - --enable-insecure-login\n            - --insecure-bind-address=0.0.0.0\n|' recommended.yaml
sed -i 's|            - --auto-generate-certificates|            - --auto-generate-certificates\n            - --enable-skip-login\n            - --disable-settings-authorizer\n|' recommended.yaml

kubectl apply -f recommended.yaml

kubectl apply -f https://raw.githubusercontent.com/tonanuvem/k8s-exemplos/master/dashboard_permission.yml

#kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'

kubectl get svc kubernetes-dashboard -n kubernetes-dashboard

# Expor ClusterIP via portforward:
ns=kubernetes-dashboard
svc=kubernetes-dashboard
port=443
echo "Expondo $svc no namespace $ns na porta $port -> local $IP:$port"
kubectl port-forward -n "$ns" "svc/$svc" "$port:$port" >/dev/null 2>&1 &


export IP=$(curl -s checkip.amazonaws.com)
echo ""
echo "Acessar K8S Dashboard: https://$IP:8099/proxy/$port"
echo ""
echo ""
