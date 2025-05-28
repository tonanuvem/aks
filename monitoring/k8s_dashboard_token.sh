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

kubectl patch svc kubernetes-dashboard -n kubernetes-dashboard -p '{"spec": {"type": "LoadBalancer"}}'
kubectl get svc kubernetes-dashboard -n kubernetes-dashboard

SERVICE_NAME=kubernetes-dashboard
NAMESPACE=kubernetes-dashboard
echo -n "Aguardando IP externo para o serviço '$SERVICE_NAME' no namespace '$NAMESPACE'"
# Espera até que o IP externo seja atribuído
while true; do
  EXTERNAL_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  
  if [ -n "$EXTERNAL_IP" ]; then
    echo -e "\n✅ IP externo disponível: $EXTERNAL_IP"
    break
  fi

  echo -n "."
  sleep 1
done

export INGRESS_PORT=$(kubectl -n kubernetes-dashboard get service kubernetes-dashboard -o jsonpath='{.spec.ports[?()].port}')
echo ""
echo "Acessar K8S Dashboard: https://$EXTERNAL_IP:$INGRESS_PORT"
echo ""
echo ""
