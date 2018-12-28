#!/usr/bin/env bash

function get_os {
  case "$OSTYPE" in
    solaris*) echo -n "SOLARIS" ;;
    darwin*)  echo -n "OSX" ;;
    linux*)   echo -n "LINUX" ;;
    freebsd*) echo -n "FREEBSD" ;;
    bsd*)     echo -n "BSD" ;;
    cygwin*)  echo -n "WINDOWS" ;;
    msys*)    echo -n "WINDOWS" ;;
    win32*)   echo -n "WINDOWS" ;;
    *)        echo -n "unknown: $OSTYPE" ;;
  esac
}

function is_windows {
  [[ "$(get_os)" = "WINDOWS" ]]
}

function is_linux {
  [[ "$(get_os)" = "LINUX" ]]
}

function is_debian {
  if is_linux; then
    if has_lsb_release; then
      lsb_release -is | grep 'Debian' > /dev/null 2>&1
    else
      cat /etc/issue | grep 'Debian' > /dev/null 2>&1
    fi
  else
    return 1
  fi
}

function is_ubuntu {
  if is_linux; then
    if has_lsb_release; then
      lsb_release -is | grep 'Ubuntu' > /dev/null 2>&1
    else
      cat /etc/issue | grep 'Ubuntu' > /dev/null 2>&1
    fi
  else
    return 1
  fi
}

function is_mint {
  if is_linux; then
    if has_lsb_release; then
      lsb_release -is | grep 'Mint' > /dev/null 2>&1
    else
      cat /etc/issue | grep 'Mint' > /dev/null 2>&1
    fi
  else
    return 1
  fi
}

function is_ubuntu {
  is_linux && cat /proc/version | grep ubuntu > /dev/null 2>&1
}

function is_ubuntu {
  is_linux && cat /proc/version | grep ubuntu > /dev/null 2>&1
}

function has_lsb_release {
  command -v lsb_release >/dev/null 2>&1
}

function windows_only {
  is_windows || die "Windows only"
}
