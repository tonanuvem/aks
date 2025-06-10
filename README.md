# Azure Kubernetes Services
Hands on : 

> az login --use-device-code

## Network Policies

Network Policies são um recurso de segurança crucial que permite controlar o fluxo de tráfego na camada de rede (L3/L4) entre os Pods dentro do cluster. No Kubernetes, controlam o fluxo de tráfego de rede em nível de Pod, pois, por padrão, todo o tráfego entre Pods é permitido. Para funcionarem, precisam usar no cluster uma CNI que tenham suporte como Calico, Weave-net ou Azure CNI.

Existem dois tipos de políticas: Ingress (para tráfego de entrada nos Pods) e Egress (para tráfego de saída dos Pods). Quando uma política é aplicada, qualquer tráfego não explicitamente permitido por política será bloqueado (comportamento "deny by default"). As políticas utilizam seletores de labels para definir a quais Pods elas se aplicam.

Seu principal caso de uso é a segmentação de rede e o isolamento de aplicações ou namespaces. Por exemplo, permitir que Pods de frontend acessem apenas Pods de backend específicos, e que Pods de backend acessem apenas o banco de dados. São cruciais para a segurança, limitando a superfície de ataque e o movimento lateral caso um Pod seja comprometido.

## Node Pools

### Resumo

| VM                     | vCPUs | RAM    | GPU              | Uso típico                       | Preço  |
|------------------------|-------|--------|------------------|---------------------------------|--------|
| Standard_A2_v2         | 2     | 4 GB   | Nenhuma          | Desenvolvimento, testes leves   | Baixo  |
| Standard_B2s           | 2     | 4 GB   | Nenhuma          | Desenvolvimento, testes leves   | Baixo  |
| Standard_D4d_v4        | 4     | 16 GB  | Nenhuma          | Produção geral, apps médias     | Médio  |
| Standard_NC4as_T4_v3   | 4     | 28 GB  | 1x NVIDIA T4 GPU | ML, AI, inferência, gráficos    | Alto   |

Tabela Resumo
| Tamanho da VM (SKU) | vCPUs | RAM (GB) | Tipo de Carga de Trabalho Ideal |
| :--- | :-: | :-: | :--- |
| Standard_B2s (Sua atual) | 2 | 4 | Burstable / Variável |
| Standard_B2ms | 2 | 8 | Burstable / Variável |
| Standard_D2s_v3 | 2 | 8 | Uso Geral / Desempenho Constante |
| Standard_D2as_v4 | 2 | 8 | Uso Geral / Desempenho Constante |
| Standard_E2s_v3 | 2 | 16 | Otimizada para Memória |
