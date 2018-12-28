#!/usr/bin/env bash

export USER="${USER:-root}"

export DEFERRED_CALLS=()

function defer {
  call="${@}"
  DEFERRED_CALLS+=("$call")
}

function call_deferreds {
  if [ ${#DEFERRED_CALLS[@]} -eq 0 ]; then
    # Se não tem chamadas deferidas, para por aqui
    return 0
  fi

  echo ""
  echo "--- deferreds call"
  echo ""

  # Efetua todas as chamadas deferidas
  for (( i = 0 ; i < ${#DEFERRED_CALLS[@]} ; i++ )); do
    echo "deferred \"${DEFERRED_CALLS[$i]}\""

    first_piece=$( echo "${DEFERRED_CALLS[$i]}" | awk '{print $1;}' )

    # Tolera erros na execução das deferidas
    set +o nounset
    set +o errexit

    if exists_function $first_piece; then
      # Se a chamada deferida for de uma funcion existente,
      # faz o call direto
      ${DEFERRED_CALLS[$i]}
    else
      bash -c "${DEFERRED_CALLS[$i]}"
    fi

  done


  echo ""
  echo "--- end deferreds"
  echo ""
}

function __cleanup {

  set -o nounset
  set -o errexit

  # chama o h_finsh pra dar suporte a trap basica
  h_finish

  call_deferreds
}

trap __cleanup EXIT

function verbose {
  [[ "$H_VERBOSE" == "true" ]]
}

function die {
  echo -e "\e[1;31m$1\e[0m" >&2
  exit "${2:-1}"
}
