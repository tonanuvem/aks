#!/bin/bash

LOG_FILE="/tmp/portforward.log"
> "$LOG_FILE"

IP=$(curl -s checkip.amazonaws.com)

function listar_servicos() {
  echo "🔍 Listando serviços disponíveis em todos os namespaces..."
  kubectl get svc --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,PORTS:.spec.ports[*].port --no-headers
}

function escolher_servico_especifico() {
  echo "➡️ Escolha o namespace:"
  kubectl get ns --no-headers | awk '{print NR ") " $1}'
  read -p "Digite o número do namespace: " ns_idx

  SELECTED_NS=$(kubectl get ns --no-headers | awk "NR==$ns_idx {print \$1}")
  echo "Selecionado namespace: $SELECTED_NS"

  echo "➡️ Escolha o serviço:"
  kubectl get svc -n "$SELECTED_NS" --no-headers | awk '{print NR ") " $1}'
  read -p "Digite o número do serviço: " svc_idx

  SELECTED_SVC=$(kubectl get svc -n "$SELECTED_NS" --no-headers | awk "NR==$svc_idx {print \$1}")
  echo "Selecionado serviço: $SELECTED_SVC"

  exportar_servico "$SELECTED_NS" "$SELECTED_SVC"
}

function exportar_servico() {
  local ns="$1"
  local svc="$2"

  PORTS_JSON=$(kubectl get svc "$svc" -n "$ns" -o jsonpath="{.spec.ports[*].port}")
  PORTS=($PORTS_JSON)

  PORT_FORWARD_ARGS=""
  for PORT in "${PORTS[@]}"; do
    LOCAL_PORT=$((PORT + RANDOM % 1000 + 10000))
    PORT_FORWARD_ARGS+="$LOCAL_PORT:$PORT "
    echo "$svc in $ns → http://$IP:$LOCAL_PORT (port $PORT)" >> "$LOG_FILE"
  done

  echo "🌐 Port-forward $svc ($ns): ${PORTS[*]}"
  kubectl port-forward svc/"$svc" $PORT_FORWARD_ARGS -n "$ns" >/dev/null 2>&1 &
}

function exportar_todos_servicos_namespace() {
  echo "➡️ Escolha o namespace:"
  kubectl get ns --no-headers | awk '{print NR ") " $1}'
  read -p "Digite o número do namespace: " ns_idx

  SELECTED_NS=$(kubectl get ns --no-headers | awk "NR==$ns_idx {print \$1}")
  echo "Selecionado namespace: $SELECTED_NS"

  for svc in $(kubectl get svc -n "$SELECTED_NS" --no-headers | awk '{print $1}'); do
    exportar_servico "$SELECTED_NS" "$svc"
  done
}

function exportar_todos_servicos_todos_namespaces() {
  for ns in $(kubectl get ns --no-headers | awk '{print $1}'); do
    for svc in $(kubectl get svc -n "$ns" --no-headers | awk '{print $1}'); do
      exportar_servico "$ns" "$svc"
    done
  done
}

function encerrar_todos_os_portforwards() {
  echo "🛑 Encerrando todos os port-forwards..."
  PIDS=$(ps aux | grep "kubectl port-forward" | grep -v grep | awk '{print $2}')
  if [ -z "$PIDS" ]; then
    echo "Nenhum processo kubectl port-forward encontrado."
  else
    echo "$PIDS" | xargs kill
    echo "Todos os port-forwards encerrados."
    > "$LOG_FILE"
  fi
}

function mostrar_menu() {
  echo
  echo "============================"
  echo "  Port-Forward Automático  "
  echo "============================"
  echo "IP Público: $IP"
  echo "1) Expor serviço específico"
  echo "2) Expor todos serviços de um namespace"
  echo "3) Expor todos serviços de todos os namespaces"
  echo "4) Listar serviços já expostos"
  echo "5) Encerrar todos os serviços expostos"
  echo "0) Sair"
  echo "----------------------------"
  read -p "Escolha uma opção: " opcao

  case $opcao in
    1) escolher_servico_especifico ;;
    2) exportar_todos_servicos_namespace ;;
    3) exportar_todos_servicos_todos_namespaces ;;
    4) echo -e "\n🌐 Serviços já expostos via port-forward:"; column -t "$LOG_FILE";;
    5) encerrar_todos_os_portforwards ;;
    0) echo "Encerrando..."; exit 0 ;;
    *) echo "Opção inválida!";;
  esac
}

while true; do
  mostrar_menu
done
