#!/usr/bin/env bash

function _list_all_commands {
  echo "/manual"
  echo "add2path"
  echo "autocomplete"

  for file in $( find $H_SPELL_DIR | grep -E ".+\.sh" | sort ) ; do
    local spell=${file#$H_SPELL_DIR/}
    local spell=${spell%.sh}

    if [[ $spell == $H_ID ]]; then
      _print_spell_actions $spell
    else
      if [[ $spell == *"/"* ]]; then
        _print_spell_actions $spell "${spell//\// }"
      else
        _print_spell_actions $spell $spell
      fi
    fi
  done
}

function _print_spell_actions {
  local spell="$1"
  local prefix="${@:2}"
  local file=$(spell_file_path $spell)
  local regex="$(action_name_regex $spell)"

  for act in $( cat $file | sed -nr "s/$regex/\5/gp" ); do
    if [[ $act == "default" ]]; then
      continue
    fi
    if [[ -z "$prefix" ]]; then
      echo "$act"
    else
      echo "$prefix $act"
    fi
  done

  if [[ -z "$prefix" ]]; then
    echo "/help"
  else
    echo "$prefix /help"
  fi
}

function setup_autocomplete {

  if [[ ! -d /etc/bash_completion.d ]]; then
    return 0
  fi

  sudo bash -c "cat - >/etc/bash_completion.d/$H_ID" <<EOM
#/usr/bin/env bash

function ___auto_complete_$H_ID {
  local possible=""
  read -r -d '' possible <<EOF
$(_list_all_commands)
EOF

  local typed="\${COMP_WORDS[@]:1}"
  local typed=\$(echo "\$typed" | xargs )
  local typed_tokens=( \$typed )

  # echo -e "\ntyped: '\$typed'" >> out.txt

  while read -r cmd; do

    if ! [[ \$cmd =~ ^\$typed[^\s]* ]] ; then
      continue
    fi

    local pieces=( \$cmd )
    local i

    for i in "\${!pieces[@]}"
    do
        local typed_token="\${typed_tokens[i]}"
        local cmd_token=\${pieces[i]}
        # echo " comparing '\$typed_token' with '\$cmd_token'" >> out.txt

        if [[ \$typed_token != \$cmd_token ]]; then
          # echo " add \$cmd_token" >> out.txt
          COMPREPLY+=( "\$cmd_token" )
          break
        fi
    done
  done <<< \$( echo "\$possible" | sort -h )

}

complete -o default -F ___auto_complete_$H_ID $H_ID
EOM
}
