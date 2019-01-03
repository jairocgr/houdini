#!/usr/bin/env bash

function spell_file_path {
  printf "$H_SPELL_DIR/$1.sh"
}

function existing_spell {
  [[ -f "$(spell_file_path $1)" ]]
}

function action_function_name {
  regex=$(action_fn_regex ${@})
  cat $(spell_file_path $1) \
    | grep -E "$regex" \
    | sed -E "s/$regex/\1/g"
}

function action_fn_regex {
  printf "^function +(((__$( echo $1 | tr '/' '_' )_)|(__))?$2) +(\( *\))?.*$"
}

function action_name_regex {
  printf "^function +(((__$( echo $1 | tr '/' '_' )_)|(__))?([a-zA-Z0-9\_]+)) +(\( *\))?.*$"
}

function existing_action {
  cat $(spell_file_path $1) | grep -E "$(action_fn_regex ${@})" >/dev/null 2>&1
}

function cast {

  local DEFAULT_SPELL="$H_ID"
  local DEFAULT_ACTION="default"

  local args=("${@}")
  local nargs="${#args[@]}"

  founded_spell=""

  for ((i=${#args[@]}; i>0; i--)); do
    pieces=("${args[@]:0:$i}")
    candidate=$(join_by / ${pieces[@]})

    if existing_spell $candidate; then
      founded_spell="$candidate"
      founded_index="$i"
      break
    fi
  done

  errmsg=""
  spell=""
  action=""

  if [[ "$founded_spell" != "" ]]; then
    spell="$founded_spell"

    canditate_index="$(( $founded_index + 1 ))"
    candidate="${!canditate_index:-}"

    if [[ "$candidate" != "" ]]; then
      if existing_action $spell $candidate; then
        action="$candidate"
        args_index="$(( $founded_index + 1 ))"
        args="${args[@]:$args_index}"
      elif existing_action $spell $DEFAULT_ACTION; then
        action="$DEFAULT_ACTION"
        args_index="$(( $founded_index ))"
        args="${args[@]:$args_index}"
      else
        errmsg="Action <b>$candidate</> not found on spell <b>$spell</>"
      fi
    else
      if existing_action $spell $DEFAULT_ACTION; then
        action="$DEFAULT_ACTION"
        args=""
      else
        errmsg="Action <b>$DEFAULT_ACTION</> not found on spell <b>$spell</>"
      fi
    fi
  else # does not found any spell
    if existing_spell $DEFAULT_SPELL; then
      spell="$DEFAULT_SPELL"

      candidate_action="${args[0]:-}"

      if [[ $candidate_action != "" ]]; then
        if existing_action $spell $candidate_action; then
          action="$candidate_action"
          args="${args[@]:1}"
        elif existing_action $spell $DEFAULT_ACTION; then
          action="$DEFAULT_ACTION"
          args="${args[@]:0}"
        else
          errmsg="Action <b>$candidate_action</> not found on <b>$spell</> spell"
        fi
      else
        if existing_action $spell $DEFAULT_ACTION; then
          action="$DEFAULT_ACTION"
          args=""
        else
          errmsg="Action <b>$DEFAULT_ACTION</> not found on default <b>$spell</> spell"
        fi
      fi
    else # does not have defaul spell
      if [[ -z "${args[0]:-}" ]]; then
        errmsg="Default spell <b>$DEFAULT_SPELL</> not found"
      else
        errmsg="Spell <b>${args[0]}</> not found"
      fi
    fi
  fi

  # If call with -h or --help, show the documentation
  if is_a_help_call; then
    spell="${spell:-$DEFAULT_SPELL}"
    action="${action:-$DEFAULT_ACTION}"
    show_man $spell $action
  fi

  if is_a_list_all_call; then
    show_list_all
  fi

  if ! [[ -z "${errmsg:-}" ]]; then
    error "$errmsg"
  fi

  ( source $(spell_file_path $spell) ; $(action_function_name $spell $action) $args )

  return $?

  ###############################

  die "$(implode / ${args[@]}).sh $nargs"

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
    elif [[ -d $H_SPELL_DIR/$candidate ]]; then
      continue;
    else
      break;
    fi

    ((i++))
  done

  die "$founded_spell / $founded_index"

  if [[ $founded_spell != "" ]]; then

    spell="$founded_spell"

    canditate_index="$( expr $founded_index + 1 )"
    candidate="${!canditate_index:-}"

    if ! [[ -z "$candidate" ]] && existing_action $spell $candidate; then
      action="$candidate"
      args_index="$(( $canditate_index + 1 ))"
      args="${@:$args_index}"
    elif existing_action $spell $DEFAULT_ACTION; then
      action="$DEFAULT_ACTION"
      args_index="$canditate_index"
      args="${@:$args_index}"
    else
      errmsg="Action \"<b>${candidate:-$DEFAULT_ACTION}</>\" not found on spell \"<b>$spell</>\""
    fi

  else
    spell="$DEFAULT_SPELL"
    candidate="${1:-}"

    if ! [[ -z "$candidate" ]] && existing_action $spell $candidate; then
      action="$candidate"
      args="${@:2}"
    elif existing_action $spell $DEFAULT_ACTION; then
      action="$DEFAULT_ACTION"
      args="${@:1}"
    else
      fail "Action \"<b>$action</>\" not found on spell \"<b>$spell</>\""
    fi
  fi

  trace "calling $spell->$action('${args:-<ZERO_ARGS>}')"

  # If call with -h or --help, show the documentation
  if is_a_help_call; then
    show_man $spell $action
  fi

  if ! existing_action $spell $action; then
    fail "Action \"<b>$action</>\" not found on spell \"<b>$spell</>\""
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
