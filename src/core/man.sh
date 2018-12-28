#!/bin/bash

function is_a_help_call {
  if [[ ${#BASH_ARGV[@]} -gt 0 ]]; then
    for arg in "${BASH_ARGV[@]}"
    do
      if [[ $arg = "--help" ]] || [[ $arg = "-h" ]] ; then
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

  file="$(spell_file_path $spell)"

  if [[ $action == "default" ]]; then

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
    echo " ALL ACTIONS" | manfmt

    regex="$(spell_actions_regex $action $spell)"

    for act in $( cat $file | sed -nr "s/$regex/\4/gp" ); do
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
  fi


  if  existing_action $1 $2; then
    echo -e "$(get_action_documentation $spell $action)"
  fi
}
