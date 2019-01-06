#!/usr/bin/env bash

function announcement {
  puts "→ <b><blue>$1</blue></b>"
}

function green_announcement {
  puts "→ <b><green>$1</green></b>"
}

function confirm {
  read -p "$1 Continue (y/n)? " choice
  case "$choice" in
    y|Y ) echo "yes";;
    n|N ) die "no";;
    * ) die "Canceled!";;
  esac
}

function error {
  puts ""
  puts " <err>ERROR:</> ${@}"
  puts ""
  exit 1
}

function putz {
  puts " ${@}"
}

function puts {
  echo -e "$( echo "${@}" \
    | sed -r 's/<red>/\\e[31m/g' \
    | sed -r 's/<\/red>/\\033[0m/g' \
    \
    | sed -r 's/<magenta>/\\e[35m/g' \
    | sed -r 's/<\/magenta>/\\033[0m/g' \
    \
    | sed -r 's/<bmagenta>/\\e[1;35m/g' \
    | sed -r 's/<\/bmagenta>/\\033[0m/g' \
    \
    | sed -r 's/<err>/\\e[1;31m/g' \
    | sed -r 's/<\/err>/\\033[0m/g' \
    \
    | sed -r 's/<gray>/\\e[90m/g' \
    | sed -r 's/<\/gray>/\\033[0m/g' \
    \
    | sed -r 's/<fade>/\\e[90m/g' \
    | sed -r 's/<\/fade>/\\033[0m/g' \
    \
    | sed -r 's/<bfade>/\\e[1;90m/g' \
    | sed -r 's/<\/bfade>/\\033[0m/g' \
    \
    | sed -r 's/<bgray>/\\e[1;90m/g' \
    | sed -r 's/<\/bgray>/\\033[0m/g' \
    \
    | sed -r 's/<green>/\\e[32m/g' \
    | sed -r 's/<\/green>/\\033[0m/g' \
    \
    | sed -r 's/<bgreen>/\\e[1;32m/g' \
    | sed -r 's/<\/bgreen>/\\033[0m/g' \
    \
    | sed -r 's/<blue>/\\e[34m/g' \
    | sed -r 's/<\/blue>/\\033[0m/g' \
    \
    | sed -r 's/<bblue>/\\e[1;34m/g' \
    | sed -r 's/<\/bblue>/\\033[0m/g' \
    \
    | sed -r 's/<cyan>/\\e[36m/g' \
    | sed -r 's/<\/cyan>/\\033[0m/g' \
    \
    | sed -r 's/<bcyan>/\\e[1;36m/g' \
    | sed -r 's/<\/bcyan>/\\033[0m/g' \
    \
    | sed -r 's/<orange>/\\e[33m/g' \
    | sed -r 's/<\/orange>/\\033[0m/g' \
    \
    | sed -r 's/<borange>/\\e[1;33m/g' \
    | sed -r 's/<\/borange>/\\033[0m/g' \
    \
    | sed -r 's/<warn>/\\e[1;33m/g' \
    | sed -r 's/<\/warn>/\\033[0m/g' \
    \
    | sed -r 's/<\/>/\\033[0m/g' \
    \
    | sed -r 's/<b>/\\033[1m/g' \
    | sed -r 's/<\/b>/\\033[0m/g' )"
}

function warn {
  puts "<warn>$1</>"
}

function red {
  puts "<red>$1</>"
}

function fail {
  puts "<err>$1</>"
}

function bold {
  puts "<b>$1</b>"
}

function fade {
  puts "<fade>$1</>"
}

function trace {
  if debug_mode; then
    puts "<gray>$1</>"
  fi
}

function info {
  puts "<cyan>$1</>"
}

function green {
  puts "<green>$1</>"
}

function success {
  puts "<bgreen>$1</>"
}

function bblue {
  puts "<bblue>${@}</>"
}

function bmagenta {
  puts "<bmagenta>${@}</>"
}

function has_arg {

  expected_arg="$1"

  for arg in ${BASH_ARGV[*]} ; do
    if [[ "$arg" == "$expected_arg" ]]; then
      return 0
    fi
  done

  return 1
}
