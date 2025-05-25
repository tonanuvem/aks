# Objetivos:

-	Capacitar os participantes a implementar e gerenciar deployments complexos no AKS.
-	Apresentar ferramentas e técnicas para automação, configuração e otimização de deployments.
-	Explorar estratégias para garantir alta disponibilidade, escalabilidade e eficiência de custos.


## Modulo 1.	Implementação de Helm Charts no AKS

 -	Introdução ao Helm: conceitos, arquitetura e benefícios.
 -	Estrutura de um Helm Chart: templates, valores e dependências.
 -	Gerenciamento de releases com Helm.

## Modulo 2.	Estratégias de CI/CD com Azure DevOps e AKS

 - Conceitos de CI/CD: integração contínua, entrega contínua e deployment contínuo.
 - Integração do Azure DevOps com AKS: agentes, pipelines e conexões de serviço.
 - Automação do processo de build, teste e deployment de aplicações no AKS.
 - Integração com o Helm para automatizar a instalação de Charts (utilizando: HelmDeploy).
 - Implementação de testes automatizados no pipeline de CI/CD (adicionando tasks de teste, como CmdLine para executar testes unitários).

## Modulo 3.	Gerenciamento de Configuração com Azure App Configuration

 -	Introdução ao Azure App Configuration: conceitos e benefícios.
 -	Armazenamento e gerenciamento centralizado de configurações de aplicações.
 -	Integração do App Configuration com aplicações em execução no AKS.
 -	Atualização dinâmica das configurações da aplicação sem necessidade de rebuild ou restart:
 -	Demonstrar como uma alteração no App Configuration é refletida na aplicação.
 -	Exemplo: Modifique um valor no App Configuration e observe a mudança na aplicação em execução no AKS.

## Modulo 4.	Práticas de Blue/Green Deployment e Canary Releases

 -	Conceitos e benefícios do Blue/Green Deployment.
 -	Implementação de Blue/Green Deployment no AKS.
 -	Conceitos e benefícios de Canary Releases.
 -	Implementação de Canary Releases no AKS.
 -	Implementação de uma estratégia de Blue/Green Deployment para uma aplicação no AKS.
 -	Utilização de seletores para controlar o tráfego entre as versões da aplicação.
 -	Implementação de uma estratégia de Canary Release para uma aplicação no AKS.

## Modulo 5.	Implementação de HPA (Horizontal Pod Autoscaling)
 -	Conceitos de escalabilidade horizontal e vertical.
 -	Introdução ao Horizontal Pod Autoscaling (HPA) no Kubernetes.
 -	Configuração do HPA com base em métricas de CPU e memória.
 -	Utilização de métricas customizadas para o HPA.
 -	Configuração do HPA para uma aplicação no AKS.
 -	Escalonamento automático do número de pods com base na utilização de CPU.
 -	Teste do HPA gerando carga na aplicação (e.g., utilizando uma ferramenta de teste de carga como hey ou loadtest).
 -	Verificação do escalonamento.
 -	Configuração do HPA para utilizar métricas customizadas (opcional -
    requer a instalação de um servidor de métricas como o Prometheus e a configuração do HPA para utilizar a métrica desejada).
 -	Instalar o Prometheus no Cluster
 -	Configurar o HPA para usar a métrica do Prometheus

## Modulo 6.	Configuração de Node Pools e Node Selectors
 -	Introdução a Node Pools no AKS: conceitos e benefícios.
 -	Criação e gerenciamento de múltiplos Node Pools.
 -	Utilização de Node Selectors e Taints/Tolerations para agendar pods em Node Pools específicos.
 -	Criação de múltiplos Node Pools no AKS
 -	Configuração de Node Selectors e Taints/Tolerations:
 -	No exemplo acima, o pool pool-cpu tem o label nodetype=cpu, e o pool pool-gpu tem o label nodetype=gpu e o taint sku=gpu:NoSchedule.
 -	Agendamento de diferentes aplicações em Node Pools específicos:
 -	Escalonamento de Node Pools:

## Modulo 7.	Gerenciamento de Custos e Otimização de Recursos
 -	Visão geral dos custos do AKS.
 -	Estratégias para otimizar o uso de recursos e reduzir custos.
 -	Utilização de Spot VMs e Reserved Instances.
 -	Monitoramento e análise de custos no Azure.
 -	Implementação de quotas e limites de recursos no AKS (exemplos de YAML):
 -	Utilização de Spot VMs para executar cargas de trabalho tolerantes a falhas:
 -	Criação de um Node Pool com Spot VMs.

 -	Análise de custos no Azure Cost Management:
 -	Acessar o Azure Cost Management no portal:
  1.	Navegue até o grupo de recursos ou assinatura do AKS no portal do Azure.
  2.	No menu à esquerda, selecione "Análise de custos".
 -	Interpretar os dados de custo:
    -	Filtre os custos por serviço (Kubernetes Service) e dimensão (Cluster Name, Node Pool).
    -	Analise os gráficos e tabelas para identificar os principais contribuintes para os custos.
 -	Implementação de recomendações de otimização de custos:
    -	Utilizar o Horizontal Pod Autoscaler (HPA) para escalar automaticamente o número de pods com base na demanda.
    -	Dimensionar os Node Pools para o tamanho apropriado para as cargas de trabalho.
    -	Utilizar o Azure Advisor para obter recomendações de otimização de custos.










