# Criação de um Role no namespace default que permite listar pods (salve como pod-reader-role.yaml):

# Aplique o Role:
kubectl apply -f role-pod-read.yaml
kubectl describe role role-pod-read

#	Criação de um RoleBinding para associar o Role a um usuário (substitua <user-email> por um usuário válido no seu sistema - 
# este é um exemplo simplificado para demonstrar RBAC dentro do cluster, a integração completa com Azure AD pode ser mais complexa e demorada):

# Aplique o RoleBinding:
kubectl apply -f pod-rolebinding-read.yaml
kubectl describe rolebinding pod-rolebinding-read

# Demonstração do uso de kubectl auth can-i:
kubectl auth can-i list pods --as=aluno@fiap.com.br -n default
kubectl auth can-i create deployments --as=aluno@fiap.com.br -n default

# O primeiro comando deve retornar "yes", 
# o segundo "no", assumindo que o Role pod-reader não concede permissão para criar deployments
