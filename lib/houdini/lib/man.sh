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

function is_a_list_all_call {
  if [[ ${#BASH_ARGV[@]} -gt 0 ]]; then
    for arg in "${BASH_ARGV[@]}"
    do
      if [[ $arg = "--list-all" ]] ; then
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
    | sed -E 's/\*(.+)\*/\\033[1m\1\\033[0m/g' \
    | sed -E 's/`(.+)`/\\033[1m\1\\033[0m/g' \
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

function show_list_all {
  puts ""
  for file in $( find $H_SPELL_DIR | grep .sh | sort ) ; do
    local spell=${file#$H_SPELL_DIR/}
    local spell=${spell%.sh}

    if [[ $spell == $H_ID ]]; then
      local default=" (default)"
    else
      local default=""
    fi

    puts " bash $H_RELATIVE_BIN <b>$spell</><fade>$default</>"
    list_spell_actions $spell
    puts ""
  done
  exit 0
}

function show_man {

  local spell="$1"
  local action="$2"

  local has_action_documentation=false
  local has_spell_documentation=false
  local errmsg=""

  if existing_action $spell $action; then
    local man="$(get_action_documentation $spell $action)"

    if [[ -z "$man" ]]; then
      errmsg="Action <b>$action</> does not have documentation"
    else
      has_action_documentation=true
      echo -e "$man\n"
    fi
  fi

  if [[ $action == "default" ]]; then

    file="$(spell_file_path $spell)"

    if [[ $has_action_documentation == "false" ]]; then
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

      if [[ "$lastcontent" != "" ]] || [[ $line_printed != "true" ]]; then
        echo ""
      fi
    fi

    if [[ $has_spell_documentation == "true" ]] || [[ $has_action_documentation == "true" ]]; then
      fade " ---\n"
    fi

    # list all actions
    puts " <b>ALL ACTIONS</> <fade>from</> <bfade>$spell</> <fade>spell</>"

    list_spell_actions $spell

    echo ""
  fi

  exit 0
}

function list_spell_actions {
  local spell="$1"
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
}
