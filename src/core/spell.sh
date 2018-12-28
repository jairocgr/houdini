#!/usr/bin/env bash

function spell_file_path {
  printf "$H_SPELL_DIR/$1.sh"
}

function existing_spell {
  [[ -f "$(spell_file_path $1)" ]]
}

function existing_spell_file {
  [[ -f "$(spell_file_path ${@})" ]]
}

function action_function_name {
  regex=$(action_fn_regex ${@})
  cat $(spell_file_path $1) \
    | grep -E "$regex" \
    | sed -E "s/$regex/\1/g"
}

function action_fn_regex {
  printf "^function +((__${1/\//_}_)|(__)?$2) *(\( *\))?.*$"
}

function spell_actions_regex {
  printf "^function +((__${1/\//_}_)|(__)?([a-zA-Z0-9\.\_]+)) *(\( *\))?.*$"
}

function existing_action_function {

  if ! existing_spell_file $1; then
    return 1
  fi

  cat $(spell_file_path $1) | grep -E "$(action_fn_regex ${@})" > /dev/null 2>&1

  return $?
}

function existing_action {
  if existing_spell $1; then
    if existing_action_function ${@}; then
      return 0
    else
      return 1
    fi
  fi
}

function cast {

  local DEFAULT_SPELL="$H_ID"
  local DEFAULT_ACTION="default"
  local args="${@}"

  founded_spell=""
  founded_index=1
  i=1

  for arg in "$@"; do
    if [[ $founded_spell == "" ]]; then
      candidate="$arg"
    else
      candidate="$candidate/$arg"
    fi

    if existing_spell "$candidate"; then
      founded_spell="$candidate"
      founded_index="$i"
    else
      break;
    fi

    ((i++))
  done

  if [[ $founded_spell != "" ]]; then

    action_index="$( expr $founded_index + 1 )"

    spell="$founded_spell"
    action="${!action_index:-}"

    if existing_action $spell $action; then
      args_index="$(( $founded_index + 2 ))"
      args="${@:$args_index}"
    else
      action="$DEFAULT_ACTION"
      args_index="$action_index"
      args="${@:$args_index}"
    fi

  else
    spell="$DEFAULT_SPELL"
    action="${1:-$DEFAULT_ACTION}"

    if existing_action $spell $action; then
      args="${@:2}"
    else
      action="$DEFAULT_ACTION"
      args="${@:1}"
    fi
  fi

  trace "calling $spell->$action('$args')"

  # If call with -h or --help, show the documentation
  if is_a_help_call; then
    show_man $spell $action
  fi

  if ! existing_action $spell $action; then
    puts ""
    puts " <err>ERROR:</> Action \"<b>$action</>\" not found on spell \"<b>$spell</>\""
    puts ""
    exit 1
  fi

  ( source $(spell_file_path $spell) ; $(action_function_name $spell $action) $args )

  return $?

  existing_action $spell $action || die "Action '$action' not found on spell '$spell'"

  if [[ ${DOCKERIZED:-} == "true" ]] && [[ $spell != "docker" ]] && [[ $spell != $H_ID ]]; then
    containerize
  fi


  trace "action: $cmd"
  trace "args:   $args"

  #die "$cmd"

  if daemonize_call ${@}; then
    castd $cmd ${@}
    return $?
  else
    #die "( $cmd $args )"
    eval "( $cmd $args )"
    return $?
  fi
}

function castd {

  daemon_name="$1"
  daemonize_dir="$H_WORKBENCH_DIR/daemonize/$daemon_name"

  mkdir -p $daemonize_dir

  args=""
  for arg in ${@:2}; do
    if ! [[  $arg =~ --*daemon* ]]; then
      args="$args $arg"
    else
      daemon_arg="$arg"
    fi
  done

  case "$daemon_arg" in
    --tail-daemon|--daemon-tail)
      tail -f -n 150 $daemonize_dir/out
      ;;
    --cat-daemon|--daemon-cat)
      cat $daemonize_dir/out
      ;;

    --status-daemon|--daemon-status)
      daemon_pid="$(cat $daemonize_dir/pid)"
      if ps -p $daemon_pid > /dev/null 2>&1; then
        green "$daemon_pid is running"
      else
        warn "$daemon_pid not running"
      fi
      ;;

    --top-daemon|--daemon-top)
      top -p $(cat $daemonize_dir/pid)
      ;;

    --stop-daemon|--kill-daemon)
      daemon_pid="$(cat $daemonize_dir/pid)"
      warn "SIGKILLing $daemon_pid..."
      kill -s KILL $daemon_pid
      ;;

    --daemon|--daemonize)
      warn "Running houdini action as daemon..."
      sudo daemonize -v -c $H_PROJECT_ROOT \
        -o $daemonize_dir/out \
        -e $daemonize_dir/out \
        -p $daemonize_dir/pid \
        -u "${USER:-root}" \
        -l $daemonize_dir/lock \
        \
        /bin/bash $H_BIN $args
      ;;

    *)
      die "Controle de daemon \"$daemon_arg\" invalido"

  esac

}

function daemonize_call {
  for arg in ${@}; do
    if [[  $arg =~ --*daemon* ]]; then
      return 0
    fi
  done

  return 1 # 1 igual a "false" em bash
}
