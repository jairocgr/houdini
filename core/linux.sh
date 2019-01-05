#!/usr/bin/env bash

function run_as_root {
  if is_linux && [[ "$(whoami)" != "root" ]]; then
    # Se for linux  e não estiver executando como root, reexecute como sudo
    sudo bash $H_BIN ${H_ARGS[@]}
    exit $?
  fi
}
