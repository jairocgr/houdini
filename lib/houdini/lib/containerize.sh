#!/usr/bin/env bash

export H_DEFAULT_CONTAINER="houdini"
export H_CONTAINER_PROJECT_ROOT="/houdini"

function containerize {

  if [[ -f /.dockerenv ]]; then
    return
  fi

  if ! command -v docker >/dev/null 2>&1; then
    error "Docker not installed!"
  fi

  local container="${1:-$H_DEFAULT_CONTAINER}"

  if docker ps -f status=running | grep $container > /dev/null 2>&1; then
    if is_windows; then
      winpty docker exec -it $container /bin/bash $H_CONTAINER_PROJECT_ROOT/$H_RELATIVE_BIN ${H_ARGS[@]}
      exit $?
    else
      docker exec -it $container /bin/bash $H_CONTAINER_PROJECT_ROOT/$H_RELATIVE_BIN ${H_ARGS[@]}
      exit $?
    fi
  else
    error "Container <b>$container</> not running!"
  fi
}
