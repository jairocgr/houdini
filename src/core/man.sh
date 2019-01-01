#!/bin/bash

function is_a_help_call {
  if [[ ${#BASH_ARGV[@]} -gt 0 ]]; then
    for arg in "${BASH_ARGV[@]}"
    do
      if [[ $arg = "--man" ]] ; then
        return 0
      fi
    done
  fi

  return 1
}

function manfmt {
  echo -e "$( cat - \
    | envsubst \
    | sed -E '/^\#\!\/.*/d' \
    | sed -E 's/<\/>/\\033[0m/g' \
    | sed -E 's/<\/b>/\\033[0m/g' \
    | sed -E 's/<b>/\\033[1m/g' \
    | sed -E 's/\*(.+)\*/\\033[1m\1\\033[0m/g' \
    | sed -E 's/`(.+)`/\\033[1m\1\\033[0m/g' \
    | sed -E 's/\#(.*)/\1/g' \
    | sed -E 's/^(\s*([A-Z0-9 \(\)]+)\s*)$/\\033[1m\1\\033[0m/g' \
  )"
}

function get_action_documentation {

  regex="$(action_fn_regex $1 $2)"

  fnline=$(cat $file | grep -nE "$regex" | cut -d: -f1)

  endline=$(( $fnline - 1 ))

  comment_size=0;

  while read line; do
    if [[ $line =~ \#.* ]]; then
      # echo "$comment_size \ $line"
      comment_size=$(($comment_size+1))
    else
      break
    fi
  done <<<$( cat $file | head -n $endline | tac )

  beginline=$(( $endline - $comment_size + 1 ))

  cat $file | head -n $endline  \
    | tail -n +$beginline \
    | manfmt
}

function get_action_description {
  while read line; do
    if [[ $line =~ ^\s*(.+)\s*$ ]]; then
      echo "$line" | manfmt
      return 0
    fi
  done <<<$( get_action_documentation ${@} )
}

function show_man {

  spell="$1"
  action="$2"

  if [[ $action == "default" ]]; then

    file="$(spell_file_path $spell)"

    # print the head comment
    while read line; do
      if [[ $line =~ \#\!.* ]]; then
        continue;
      elif [[ $line =~ \#.* ]]; then
        echo "$line" | manfmt
      else
        break
      fi
    done <<<$( cat $file )

    # list all actions
    echo ""
    echo " ALL ACTIONS" | manfmt

    regex="$(action_name_regex $spell)"

    for act in $( cat $file | sed -nr "s/$regex/\5/gp" ); do
      # echo "-> get_action_description $spell $action"
      # get_action_description $spell $act
      # die "man"
      description="$( get_action_description $spell $act )"
      if [[ -z "$description" ]]; then
        puts "  <b>$act</>"
      else
        msg="  <b>$act</> — ${description}"

        if [[ ${#msg} -gt 76 ]]; then
          echo "${msg:0:73}..." | manfmt
        else
          echo "$msg" | manfmt
        fi
      fi

    done

    echo ""

    if existing_action $spell $action; then
      local man="$(get_action_documentation $spell $action)"

      if ! [[ -z "$man" ]]; then
        echo -e "$man"
        echo ""
      fi
    fi

    exit 0
  fi


  if existing_action $1 $2; then
    local man="$(get_action_documentation $spell $action)"

    if [[ -z "$man" ]]; then
      error "Action <b>$action</> does not have documentation"
    else
      echo -e "$man\n"
    fi
  fi

  exit 0
}
