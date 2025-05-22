# Explicação sobre a importância do SSL/TLS, diferentes formas de configurar (certificados gerenciados pelo Kubernetes, soluções como cert-manager, integração com Azure Key Vault). 
# Foco na configuração básica com um Ingress Controller.

#	Instalação de um Ingress Controller (Nginx Ingress Controller):

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.0/deploy/static/provider/cloud/deploy.yaml

#	Criação de um certificado autoassinado (para teste):

openssl genrsa -out tls.key 2048
openssl req -new -key tls.key -out server.csr -subj "/CN=example.com"
openssl x509 -req -days 365 -in server.csr -signkey tls.key -out tls.crt
kubectl create secret tls tls-secret --key tls.key --cert tls.crt

# Deploy de uma aplicação web simples (ex: network/nginx-deploy-a).

