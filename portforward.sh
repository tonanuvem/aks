#!/bin/sh

IP=$(curl -s checkip.amazonaws.com)

list_namespaces() {
  kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name} {end}'
}

list_services() {
  ns=$1
  kubectl get svc -n "$ns" -o jsonpath='{range .items[*]}{.metadata.name}:{.spec.ports[0].port} {end}'
}

port_forwards_pids_file="/tmp/k8s-port-forward-pids.txt"

start_port_forward() {
  ns=$1
  svc=$2
  port=$3
  echo "Expondo $svc no namespace $ns na porta $port -> local $IP:$port"
  kubectl port-forward -n "$ns" "svc/$svc" "$port:$port" >/dev/null 2>&1 &
  echo "$!" >> "$port_forwards_pids_file"
}

list_active_port_forwards() {
  echo "Port-forwards ativos (PID):"
  
  # Pega todos os processos com 'kubectl port-forward'
  # Exclui a linha do próprio grep (com grep -v)
  # Formata: PID e comando completo
  ps aux | grep "[k]ubectl port-forward" | awk '{print $2, substr($0, index($0,$11))}'

  # Se quiser uma mensagem quando não achar nenhum
  if ! ps aux | grep -q "[k]ubectl port-forward"; then
    echo "  Nenhum port-forward ativo encontrado."
  fi
}


kill_all_port_forwards() {
  if [ -f "$port_forwards_pids_file" ]; then
    while read pid; do
      echo "Matando port-forward PID $pid"
      kill "$pid" 2>/dev/null
    done < "$port_forwards_pids_file"
    rm -f "$port_forwards_pids_file"
  else
    echo "Nenhum port-forward para matar."
  fi
}

main_menu() {
  while true; do
    echo ""
    echo "1) Listar namespaces"
    echo "2) Listar serviços de um namespace e expor selecionados"
    echo "3) Expor todos os serviços de um namespace"
    echo "4) Expor todos os serviços de todos os namespaces"
    echo "5) Listar port-forwards ativos"
    echo "6) Encerrar todos port-forwards"
    echo "0) Sair"
    echo -n "Escolha uma opção: "
    read opt

    case "$opt" in
      1)
        echo "Namespaces disponíveis:"
        list_namespaces | tr ' ' '\n'
        ;;
      2)
        echo -n "Digite o namespace: "
        read ns
        echo "Serviços em $ns:"
        svcs=$(list_services "$ns")
        if [ -z "$svcs" ]; then
          echo "Nenhum serviço encontrado."
          continue
        fi
        i=1
        for svc_port in $svcs; do
          svc=$(echo "$svc_port" | cut -d: -f1)
          port=$(echo "$svc_port" | cut -d: -f2)
          echo "$i) $svc (porta $port)"
          i=$((i + 1))
        done
        echo -n "Digite o número do serviço para expor (ou 0 para cancelar): "
        read svc_choice
        if [ "$svc_choice" -eq 0 ]; then
          continue
        fi
        selected_svc_port=$(echo $svcs | cut -d' ' -f "$svc_choice")
        svc=$(echo "$selected_svc_port" | cut -d: -f1)
        port=$(echo "$selected_svc_port" | cut -d: -f2)
        start_port_forward "$ns" "$svc" "$port"
        ;;
      3)
        echo -n "Digite o namespace: "
        read ns
        svcs=$(list_services "$ns")
        for svc_port in $svcs; do
          svc=$(echo "$svc_port" | cut -d: -f1)
          port=$(echo "$svc_port" | cut -d: -f2)
          start_port_forward "$ns" "$svc" "$port"
        done
        ;;
      4)
        for ns in $(list_namespaces); do
          svcs=$(list_services "$ns")
          for svc_port in $svcs; do
            svc=$(echo "$svc_port" | cut -d: -f1)
            port=$(echo "$svc_port" | cut -d: -f2)
            start_port_forward "$ns" "$svc" "$port"
          done
        done
        ;;
      5)
        list_active_port_forwards
        ;;
      6)
        kill_all_port_forwards
        ;;
      0)
        echo "Saindo."
        exit 0
        ;;
      *)
        echo "Opção inválida."
        ;;
    esac
  done
}

main_menu
