# Configurar o Cert-Manager com Let's Encrypt (via DNS-01) usando o AWS Route 53 para o domínio = tonanuvem.com.
## Objetivo : Emitir certificados TLS automáticos e wildcard (*.tonanuvem.com) usando o Cert-Manager com a API da AWS Route 53.

### Pré-requisitos: 

    - Domínio gerenciado no Route 53

    - Cert-Manager já instalado no cluster

    - Uma IAM user ou role com permissões para gerenciar DNS (pelo menos route53:ChangeResourceRecordSets e route53:ListHostedZones)

    - Sua chave AWS (AWS_ACCESS_KEY_ID e AWS_SECRET_ACCESS_KEY)


### Etapas:

- 1. Criar um Secret com as credenciais da AWS:

    - Coloque as credenciais com permissão para gerenciar seu domínio no Route 53.

> kubectl create secret generic route53-credentials-secret \
  --from-literal=aws_access_key_id=SEU_ACCESS_KEY_ID \
  --from-literal=aws_secret_access_key=SEU_SECRET_ACCESS_KEY \
  -n cert-manager

- 2. Criar um ClusterIssuer usando o DNS-01 via Route 53

> clusterissuer-route53.yaml
'''
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-route53
spec:
  acme:
    email: seu-email@tonanuvem.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-route53
    solvers:
    - dns01:
        route53:
          region: us-east-1  # ajuste conforme a região do seu hosted zone
          hostedZoneID: ""   # pode deixar em branco se não quiser fixar
          accessKeyIDSecretRef:
            name: route53-credentials-secret
            key: aws_access_key_id
          secretAccessKeySecretRef:
            name: route53-credentials-secret
            key: aws_secret_access_key
'''

kubectl apply -f clusterissuer-route53.yaml

- Criar um Ingress para *.tonanuvem.com com TLS automático

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-tonanuvem
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-route53
spec:
  tls:
    - hosts:
        - "*.tonanuvem.com"
      secretName: tonanuvem-tls
  rules:
    - host: app.tonanuvem.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx
                port:
                  number: 80

kubectl apply -f ingress-tonanuvem.yaml

- (Opcional) Verificar certificado emitido

kubectl describe certificate -A

Pode usar subdomínio de tonanuvem.com no seu cluster com HTTPS automático (ex: api.tonanuvem.com, app.tonanuvem.com, etc.)

    Criar novos Ingress com o mesmo secretName: tonanuvem-tls
