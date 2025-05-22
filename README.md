# Azure Kubernetes Services
Hands on

## Network Policies

Network Policies são um recurso de segurança crucial que permite controlar o fluxo de tráfego na camada de rede (L3/L4) entre os Pods dentro do cluster. No Kubernetes, controlam o fluxo de tráfego de rede em nível de Pod, pois, por padrão, todo o tráfego entre Pods é permitido. Para funcionarem, precisam usar no cluster uma CNI que tenham suporte como Calico, Weave-net ou Azure CNI.

Existem dois tipos de políticas: Ingress (para tráfego de entrada nos Pods) e Egress (para tráfego de saída dos Pods). Quando uma política é aplicada, qualquer tráfego não explicitamente permitido por política será bloqueado (comportamento "deny by default"). As políticas utilizam seletores de labels para definir a quais Pods elas se aplicam.

Seu principal caso de uso é a segmentação de rede e o isolamento de aplicações ou namespaces. Por exemplo, permitir que Pods de frontend acessem apenas Pods de backend específicos, e que Pods de backend acessem apenas o banco de dados. São cruciais para a segurança, limitando a superfície de ataque e o movimento lateral caso um Pod seja comprometido.

# Componentes de Rede Criados e Gerenciados pelo AKS

Quando você cria um cluster AKS, vários componentes de rede são configurados:

- Sub-rede(s) do AKS: podem ser criadas sub rede separadas para os nós e para os Pods.
- Service CIDR: são definidos ranges de IPs virtuais (não existem na VNet) usado para os Services do Kubernetes do tipo ClusterIP. Padrão: 10.0.0.0/16.
- DNS Service IP: é definido um endereço IP dentro do Service CIDR (ex: 10.0.0.10) atribuído ao serviço de DNS interno do cluster (geralmente CoreDNS).
- Load Balancer (Público ou Interno): quando se cria um Service do Kubernetes do tipo LoadBalancer, o AKS provisiona um Azure Load Balancer. Ele recebe um IP público (se for um LB público) ou um IP privado da sua VNet (se for um LB interno) e distribui o tráfego para os nós/Pods apropriados.
- Network Security Groups (NSGs): AKS cria e gerencia NSGs (que possuem as regras de firewall) aplicados automaticamente às interfaces de rede (NICs) dos nós.
Esses NSGs contêm regras para permitir o tráfego essencial para a operação do cluster (ex: comunicação do kubelet com o API server) e para o tráfego de entrada definido pelos seus Services do tipo LoadBalancer ou NodePort. NSGs operam no nível da VM/NIC (L3/L4), enquanto Network Policies operam no nível do Pod.

# Fluxo de Tráfego com Network Policies (Exemplo de Entrada):

Propósito:
Definir quais Pods podem se comunicar com quais outros Pods, com quais namespaces ou com IPs externos, e em quais portas/protocolos.

Fluxo:
- Tráfego externo chega a um Service LoadBalancer.
- O Azure Load Balancer encaminha o tráfego para um dos nós do AKS.
- O NSG associado à NIC do nó deve permitir esse tráfego (ex: para a porta do NodePort).
- O kube-proxy do nó recebe o tráfego e o direciona para o IP do Pod de destino.
- **Neste ponto, a *Network Policy* é avaliada:**
  - Se houver uma política de **Ingress** aplicada:
    - Ela verificará se o **Pod**, **namespace**, **porta** e **protocolo** estão permitidos.
  - Se **não houver** uma regra de permissão correspondente:
    - O tráfego será **bloqueado** por padrão.

