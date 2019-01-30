#!/bin/bash

function is_a_help_call {
  if [[ ${#BASH_ARGV[@]} -gt 0 ]]; then
    for arg in "${BASH_ARGV[@]}"
    do
      if [[ $arg = "/help" ]] ; then
        return 0
      fi
    done
  fi

  return 1
}

function manfmt {
  echo -e "$( cat - \
    | sed -E '/^\#\!\/.*/d' \
    | sed -E 's/<\/>/\\033[0m/g' \
    | sed -E 's/<\/b>/\\033[0m/g' \
    | sed -E 's/<b>/\\033[1m/g' \
    | sed -r 's/<fade>/\\e[90m/g' \
    | sed -E 's/\*([^\*]+)\*/\\033[1m\1\\033[0m/g' \
    | sed -E 's/`([^`]+)`/\\033[1m\1\\033[0m/g' \
    | sed -E 's/\#(.*)/\1/g' \
    | sed -E 's/^(\s*([A-Z0-9 \(\)]+)\s*)$/\\033[1m\1\\033[0m/g' \
  )"
}

function get_action_documentation {

  local file="$(spell_file_path $1)"

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

function has_other_spells {
  for file in $( find $H_SPELL_DIR | grep -E ".+\.sh" | sort ) ; do
    local spell=${file#$H_SPELL_DIR/}
    local spell=${spell%.sh}

    if [[ $spell == $H_ID ]]; then
      # If is default spell, don't count
      continue
    fi

    return 0
  done
  return 1
}

function print_manual {
  putz ""
  putz "Ferramenta <b>$H_ID</> de linha de comando"
  putz ""
  putz "<b>USAGE</>"
  putz " $ $H_ID <spell> <action> params..."
  putz ""
  putz "<b>SPELLS DISPONÍVEIS</>"
  putz ""
  if existing_spell $H_ID; then
    putz " <b>$spell</> <fade>(default)</>"
  fi

  for file in $( find $H_SPELL_DIR | grep -E ".+\.sh" | sort ) ; do
    local spell=${file#$H_SPELL_DIR/}
    local spell=${spell%.sh}

    if [[ $spell == $H_ID ]]; then
      # If is default spell, don't print
      continue
    fi

    putz " $H_ID <b>$spell</>"
  done
  putz ""
  putz "<b>AJUDA</>"
  putz " $ $H_ID <spell> /help"
  putz ""
  exit 0
}

function print_action_man {

  local spell="$1"
  local action="$2"

  if existing_action $spell $action; then
    local man="$(get_action_documentation $spell $action)"

    if [[ -z "$man" ]]; then
      error "Action <b>$action</> does not have documentation"
    else
      echo -e "$man\n"
    fi
  fi

  exit 0
}

function print_spell_man {
  local spell="$1"

  file="$(spell_file_path $spell)"

  # show header comment
  local lastcontent=""
  local line_printed=false

  # print the head comment
  while read line; do
    if [[ $line =~ \#\!.* ]]; then
      continue;
    elif [[ $line =~ \#.* ]]; then
      line_printed=true
      has_spell_documentation=true
      lastcontent="$(echo $line | manfmt | xargs)"
      echo "$line" | manfmt
    else
      break
    fi
  done <<<$( cat $file )

  # if [[ $line_printed == "false" ]]; then
  #   error "Spell <b>$spell</> does not have documentation"
  # fi

  if [[ "$lastcontent" != "" ]] || [[ $line_printed != "true" ]]; then
    echo ""
  fi

}

function print_spell_actions {
  local spell="$1"

  print_spell_man $spell

  putz "<b>ACTIONS</> do spell <b>$spell</>"

  local file=$(spell_file_path $spell)
  local regex="$(action_name_regex $spell)"

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


  putz ""
  putz "<b>AJUDA</>"
  putz " $ $H_ID $spell <action> /help"
  putz ""

  echo ""
  exit 0
}
