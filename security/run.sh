# Explicação sobre a importância do SSL/TLS, diferentes formas de configurar (certificados gerenciados pelo Kubernetes, soluções como cert-manager, integração com Azure Key Vault). 
# Foco na configuração básica com um Ingress Controller.

#	Instalação de um Ingress Controller (Nginx Ingress Controller):

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/cloud/deploy.yaml

#	Criação de um certificado autoassinado (para teste):

openssl genrsa -out tls.key 2048
openssl req -new -key tls.key -out server.csr -subj "/CN=sslip.io"
openssl x509 -req -days 365 -in server.csr -signkey tls.key -out tls.crt
kubectl create secret tls tls-secret --key tls.key --cert tls.crt

# Deploy de uma aplicação web simples (ex: network/nginx-deploy-a).

kubectl apply -f nginx-deploy.yaml
kubectl apply -f nginx-service-clusterip.yaml
#kubectl apply -f nginx-service-loadbalancer.yaml

# Aguardar até que o IP Externo seja alocado

sh wait-for-lb-ip.sh ingress-nginx-controller ingress-nginx

#	Criação de um recurso Ingress para expor a aplicação através de HTTPS (ingress-ssl.yaml):

IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
HOST="$IP.sslip.io"
echo $HOST

# Substituir HOST no YAML do INGRESS usando envsubst
# envsubst < ingress-ssl.yaml | kubectl apply -f -

export HOST

# Aplicar o Ingress:

envsubst < ingress-http.yaml > ingress-http-final.yaml
kubectl apply -f ingress-http-final.yaml

envsubst < ingress-ssl.yaml > ingress-ssl-final.yaml
kubectl apply -f ingress-ssl-final.yaml

kubectl get ingress -n default

# Obter o endereço do Ingress Controller:
kubectl get service -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Acesse a aplicação via HTTP e  HTTPS no navegador usando o IP obtido ou o domínio configurado

echo ""
echo "Acesso via HTTP : http://$HOST"
echo ""
echo "Acesso via HTTPS : https://$HOST"
