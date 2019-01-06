#!/usr/bin/env bash

function exists_function {
  test "$(type -t $1)" = "function"
}

function command_exists {
  command -v $1 >/dev/null 2>&1
}

function indent {
  sed 's/^/  /'
}

function join_by {
  local IFS="$1"
  shift
  echo -n "$*"
}

function not_empty {
  [[ ! -z "${@:-}" ]]
}
