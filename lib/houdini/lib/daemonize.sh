#!/usr/bin/env bash

DAEMONIZE_WORK_DIR="$H_WORKBENCH_DIR/daemonize"

function castd {

  local daemon_name="$1"

  # Remove daemonizing arguments from arg list
  local args=""
  local daemon_arg=""
  for arg in ${@:2}; do
    if ! [[  $arg =~ --*daemon* ]]; then
      args="$args $arg"
    else
      daemon_arg="$arg"
    fi
  done

  case "$daemon_arg" in
    --tail-daemon|--daemon-tail)
      daemonizer tail $daemon_name
      ;;

    --status-daemon|--daemon-status)
      daemonizer status $daemon_name
      ;;

    --rm-daemon|--daemon-rm)
      daemonizer rm $daemon_name
      ;;

    --stop-daemon|--kill-daemon|--daemon-stop|--daemon-kill)
      daemonizer kill $daemon_name
      ;;

    --daemon|--daemonize)
      daemonizer run $daemon_name $args
      ;;

    *)
      die "Daemon controll \"$daemon_arg\" does not exists"

  esac
}

function daemonizer {
  local action="${1:-}"

  case "$action" in
    run)
      daemon_run ${@:2}
      ;;

    ls)
      daemon_ls
      ;;

    tail)
      daemon_tail ${@:2}
      ;;

    status)
      daemon_status ${@:2}
      ;;

    rm)
      daemon_rm ${@:2}
      ;;

    kill|stop)
      daemon_kill ${@:2}
      ;;

    *)

      if [[ -z "$action" ]]; then
        daemonizer ls
      elif daemon_exists $action; then
        daemonizer tail $action
      else
        error "Daemon <b>$action</> does not exist!"
      fi

  esac
}

function is_daemonize_call {
  for arg in ${@}; do
    if [[  $arg =~ --*daemon* ]]; then
      return 0
    fi
  done

  return 1
}

function daemon_exists {
  has_daemons || return 1

  local given_daemon=$1

  for daemon in $( ls $DAEMONIZE_WORK_DIR ); do
    local pid="$(get_daemon_pid $daemon)"
    if [[ $given_daemon == $daemon ]] || [[ $pid == $given_daemon ]]; then
      return 0
    fi
  done

  return 1
}

function daemon_run {
  local daemon_name="$1"
  local daemon_dir="$DAEMONIZE_WORK_DIR/$daemon_name"
  local args="${@:2}"

  if daemon_is_running $daemon_name; then
    error "Deamon already running!"
  fi

  putz ""
  putz "Running as a daemon..."

  mkdir -p $daemon_dir

  echo "$args" > $daemon_dir/args

  bash -c "bash $H_BIN $args &>$daemon_dir/out & echo \$!" \
    > $daemon_dir/pid

  putz ""
}

function daemon_kill {

  require_existing_daemons

  not_empty "${1:-}" || error "No given deamon to rm"
  daemon_exists $1 || error "Daemon <b>$1</> does not exists!"

  local daemon=$(lookup_daemon_name $1)
  local pid=$( get_daemon_pid $daemon )

  putz ""
  putz "killing <b>$daemon</>, pid <warn>$pid</>..."

  set +o errexit
  pkill -15 -P $pid > /dev/null 2>&1

  while ps -p $pid > /dev/null 2>&1 ; do
    putz " waiting daemon to die..."
    sleep 1
  done

  set -o errexit
  putz ""
}

function get_daemon_pid {
  cat $DAEMONIZE_WORK_DIR/$1/pid | tr -d '\n'
}

function lookup_daemon_name {
  has_daemons || return

  local handle=$1

  for daemon in $( ls $DAEMONIZE_WORK_DIR ); do
    if [[ $handle == $daemon ]] || [[ $handle == $(get_daemon_pid $daemon) ]]; then
      echo -n "$daemon"
    fi
  done
}

function daemon_tail {
  require_existing_daemons

  not_empty "${1:-}" || error "No given deamon to tail"
  daemon_exists $1 || error "Daemon <b>$1</> does not exists!"

  local daemon=$(lookup_daemon_name $1)
  local daemon_pid=$(get_daemon_pid $daemon)

  if daemon_is_running $daemon; then
    local status="is <green>running</><fade>, pid </><bfade>$daemon_pid</><fade>"
  else
    local status="not running, pid <bfade>$daemon_pid</><fade>"
  fi

  fade "tailing -f <bfade>$daemon</><fade> ($status)"
  tail -f $DAEMONIZE_WORK_DIR/$daemon/out
}

function daemon_rm {
  require_existing_daemons

  not_empty "${1:-}" || error "No given deamon to rm"
  daemon_exists $1 || error "Daemon <b>$1</> does not exists!"

  local daemon=$(lookup_daemon_name $1)

  if daemon_is_running $daemon; then
    error "Daemon is running, you must kill it first!"
  fi

  putz ""
  putz "Removing deamon <b>$daemon</>, pid <b>$(get_daemon_pid $daemon)</>"
  rm -rf $DAEMONIZE_WORK_DIR/$daemon
  putz ""
}

function daemon_status {
  require_existing_daemons

  not_empty "${1:-}" || error "No given deamon to status"
  daemon_exists $1 || error "Daemon <b>$1</> does not exists!"

  local daemon=$(lookup_daemon_name $1)

  putz ""
  print_daemon_status $daemon
  putz ""
}

function print_daemon_status {
  local daemon_dir="$DAEMONIZE_WORK_DIR/$daemon"
  local daemon_pid="$(get_daemon_pid $daemon)"
  local daemon_args="$(cat $daemon_dir/args)"

  if daemon_is_running $daemon; then
    local status="is <green>running</>, pid <b>$daemon_pid</>"
  else
    local status="<fade>not running</>, pid <b>$daemon_pid</>"
  fi

  local cmd="bash $H_RELATIVE_BIN $daemon_args"

  if [[ ${#cmd} -gt 72 ]]; then
    local cmd="${cmd:0:69}..."
  fi

  putz "<b>$daemon</> $status"
  putz " <fade>$cmd</>"
}

function has_daemons {
  if [[ -d $DAEMONIZE_WORK_DIR ]]; then
    daemons="$( ls $DAEMONIZE_WORK_DIR )"

    if [[ ! -z "$daemons" ]]; then
      return 0
    else
      return 1
    fi
  else
    return 1
  fi
}

function not_has_daemons {
  has_daemons | false
}

function require_existing_daemons {
  has_daemons || error "No daemon running"
}

function daemon_is_running {

  local given_daemon=$1

  if ! daemon_exists $given_daemon; then
    return 1
  fi

  for daemon in $( ls $DAEMONIZE_WORK_DIR ) ; do
    local pid="$(cat $DAEMONIZE_WORK_DIR/$daemon/pid)"
    if [[ $given_daemon == $daemon ]] || [[ $pid == $given_daemon ]]; then
      if ps -p $pid > /dev/null 2>&1 ; then
        return 0
      else
        return 1
      fi
    fi
  done

  return 1
}

function daemon_ls {
  require_existing_daemons

  putz ""
  for daemon in $( ls $DAEMONIZE_WORK_DIR ) ; do
    print_daemon_status $daemon
    putz ""
  done
}
