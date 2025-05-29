#!/bin/bash

#    Obtém o IP do LoadBalancer
#    Gera o certificado autoassinado
#    Cria o Secret TLS no Kubernetes
#    Gera automaticamente um Ingress YAML com o domínio sslip.io
#    Aplica o Ingress no cluster

set -e

NAMESPACE="ingress-nginx"                # ajuste se necessário
SERVICE_NAME="ingress-nginx-controller"  # ajuste se necessário
SECRET_NAME="tls-secret"
INGRESS_NAME="ingress-sslip"
SERVICE_BACKEND="nginx"                  # nome do serviço backend
SERVICE_PORT=80                          # porta do serviço backend

echo "📡 Obtendo IP externo do LoadBalancer..."
LB_IP=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

if [ -z "$LB_IP" ]; then
  echo "❌ IP do LoadBalancer não encontrado. Verifique se o serviço foi exposto corretamente."
  exit 1
fi

DOMAIN="${LB_IP//./-}.sslip.io"
echo "✅ IP encontrado: $LB_IP"
echo "🌐 Domínio: $DOMAIN"

# Criação do arquivo de configuração para OpenSSL com SAN
cat > cert.cnf <<EOF
[req]
distinguished_name=req
x509_extensions=v3_req
prompt=no

[req_distinguished_name]
CN=${DOMAIN}

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
EOF

echo "🔐 Gerando certificado autoassinado..."
openssl req -new -nodes -newkey rsa:2048 \
  -keyout tls.key -out tls.csr \
  -config cert.cnf

openssl x509 -req -in tls.csr -signkey tls.key -out tls.crt -days 365 \
  -extensions v3_req -extfile cert.cnf

echo "📦 Criando Secret TLS no Kubernetes..."
kubectl create secret tls "$SECRET_NAME" \
  --cert=tls.crt --key=tls.key -n "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "📝 Gerando arquivo de Ingress: ingress-$DOMAIN.yaml"

cat > "ingress-$DOMAIN.yaml" <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $INGRESS_NAME
  namespace: $NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  tls:
    - hosts:
        - $DOMAIN
      secretName: $SECRET_NAME
  rules:
    - host: $DOMAIN
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: $SERVICE_BACKEND
                port:
                  number: $SERVICE_PORT
EOF

echo "🚀 Aplicando Ingress no cluster..."
kubectl apply -f "ingress-$DOMAIN.yaml"

echo "✅ Tudo pronto!"
echo "🌐 Acesse: https://$DOMAIN"

# Limpeza de arquivos temporários
rm -f tls.key tls.csr tls.crt cert.cnf
