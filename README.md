# aks
Azure Kubernetes hands on

## Network Policies

Network Policies no Kubernetes controlam o fluxo de tráfego de rede em nível de Pod. Por padrão, todo o tráfego entre Pods é permitido. Para funcionarem, precisam usar no cluster uma CNI que tenham suporte como Calico, Weave-net ou Azure CNI.

Existem dois tipos de políticas: Ingress (para tráfego de entrada nos Pods) e Egress (para tráfego de saída dos Pods). Quando uma política é aplicada, qualquer tráfego não explicitamente permitido por política será bloqueado (comportamento "deny by default"). As políticas utilizam seletores de labels para definir a quais Pods elas se aplicam.

Seu principal caso de uso é a segmentação de rede e o isolamento de aplicações ou namespaces. Por exemplo, permitir que Pods de frontend acessem apenas Pods de backend específicos, e que Pods de backend acessem apenas o banco de dados. São cruciais para a segurança, limitando a superfície de ataque e o movimento lateral caso um Pod seja comprometido.
