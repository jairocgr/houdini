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

function add2path {
  if is_windows; then
    die "can't add to path if windows!"
  fi

  sudo rm -rf /usr/bin/$H_ID

  sudo ln -s $H_BIN /usr/bin/$H_ID

  sudo chmod +x $H_BIN
  sudo chmod +x /usr/bin/$H_ID

  # setup_autocomplete
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

  local errmsg=""
  local spell=""
  local action=""
  local candidate_action=""

  if [[ "$founded_spell" != "" ]]; then
    spell="$founded_spell"

    canditate_index="$(( $founded_index + 1 ))"
    candidate_action="${!canditate_index:-}"

    if [[ "$candidate_action" != "" ]]; then
      if existing_action $spell $candidate_action; then
        action="$candidate_action"
        args_index="$(( $founded_index + 1 ))"
        args="${args[@]:$args_index}"
      elif [[ $candidate_action == "help" ]]; then
        print_spell_actions $spell
      elif [[ $candidate_action == "list" ]]; then
        if [[ $spell == $H_ID ]]; then
          print_all_spells
        else
          print_spell_actions $spell
        fi
      elif [[ $candidate_action == "add2path" ]]; then
        add2path
        return $?
      elif existing_action $spell $DEFAULT_ACTION; then
        action="$DEFAULT_ACTION"
        args_index="$(( $founded_index ))"
        args="${args[@]:$args_index}"
      else
        errmsg="Action <b>$candidate_action</> not found on spell <b>$spell</>"
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
        elif [[ $candidate_action == "help" ]]; then
          print_spell_actions $spell
        elif [[ $candidate_action == "add2path" ]]; then
          add2path
          return $?
        elif [[ $candidate_action == "list" ]]; then
          print_all_spells
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
      elif [[ "${args[0]:-}" == "list" ]]; then
        print_all_spells
      elif [[ "${args[0]:-}" == "add2path" ]]; then
        add2path
        return $?
      else
        errmsg="Spell <b>${args[0]}</> not found"
      fi
    fi
  fi

  if ! [[ -z "${errmsg:-}" ]]; then
    error "$errmsg"
  fi

  # If call with -h or --help, show the documentation
  if is_a_help_call; then
    spell="${spell:-$DEFAULT_SPELL}"
    action="${action:-$DEFAULT_ACTION}"
    print_action_man $spell $action
  fi

  if is_daemonize_call ${@}; then
    castd "$(echo $spell/$action | tr '/' '_')" ${@}
    return $?
  else
    source $(spell_file_path $spell) ; $(action_function_name $spell $action) $args
    return $?
  fi
}
