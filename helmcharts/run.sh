# Modulo 1:	Implementação de Helm Charts no AKS
#	Criação de um Helm Chart básico para uma aplicação de exemplo:
helm create my-nginx-chart

# Customização do Chart utilizando valores e templates, editar: 
  > my-nginx-chart/values.yaml e 
  > my-nginx-chart/templates/deployment.yaml).
  
# Instalação do Chart no AKS:
helm install my-nginx-release ./my-nginx-chart

# Upgrade do Chart:
# Modificar o Chart (e.g., versão da imagem)
helm upgrade my-nginx-release ./my-nginx-chart

#	Utilização de repositórios de Helm (públicos e privados):
helm repo add bitnami https://charts.bitnami.com/bitnami
helm search repo bitnami/nginx
helm install my-bitnami-nginx bitnami/nginx

# Modulo 2.	Estratégias de CI/CD com Azure DevOps e AKS
# Conceitos de CI/CD: integração contínua, entrega contínua e deployment contínuo.
#	Integração do Azure DevOps com AKS: agentes, pipelines e conexões de serviço.
#	Automação do processo de build, teste e deployment de aplicações no AKS.


