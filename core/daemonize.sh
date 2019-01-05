#!/usr/bin/env bash

DAEMONIZE_WORK_DIR="$H_WORKBENCH_DIR/daemonize"

function castd {

  local daemon_name="$1"

  # Remove daemonizing arguments from arg list
  local args=""
  for arg in ${@:2}; do
    if ! [[  $arg =~ --*daemon* ]]; then
      args="$args $arg"
    fi
  done

  daemonizer run $daemon_name $args
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

function daemonize_call {
  for arg in ${@}; do
    if [[  $arg == "--daemon" ]] || [[  $arg == "--daemonize" ]]; then
      return 0
    fi
  done

  return 1
}

function daemon_exists {
  if [[ ! -d $DAEMONIZE_WORK_DIR ]]; then
    return 1
  fi

  for daemon in $( ls $DAEMONIZE_WORK_DIR ); do
    daemon=${daemon#$DAEMONIZE_WORK_DIR/}
    if [[ $1 == $daemon ]] || [[ $(cat $DAEMONIZE_WORK_DIR/$daemon/pid) == $1 ]]; then
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

  if [[ ! -d $DAEMONIZE_WORK_DIR ]]; then
    error "No daemons running"
  fi

  for daemon in $( ls $DAEMONIZE_WORK_DIR ) ; do
    daemon=${daemon#$DAEMONIZE_WORK_DIR/}
    if [[ ${1:-} == $daemon ]] || [[ $(cat $DAEMONIZE_WORK_DIR/$daemon/pid) == ${1:-} ]]; then
      local pid=$( cat $DAEMONIZE_WORK_DIR/$daemon/pid )
      putz ""
      putz "killing <b>$daemon</>, pid <warn>$pid</>..."

      set +o errexit
      pkill -15 -P $pid > /dev/null 2>&1

      while ps -p $pid > /dev/null 2>&1 ; do
        putz " waiting daemon to die..."
        sleep 1
      done

      putz ""
      set -o errexit
    fi
  done
}

function daemon_tail {

  if [[ ! -d $DAEMONIZE_WORK_DIR ]]; then
    error "No daemons running"
  fi

  for daemon in $( ls $DAEMONIZE_WORK_DIR ) ; do
    daemon=${daemon#$DAEMONIZE_WORK_DIR/}

    if [[ $1 == $daemon ]] || [[ $(cat $DAEMONIZE_WORK_DIR/$daemon/pid) == $1 ]]; then

      daemon_pid="$(cat $DAEMONIZE_WORK_DIR/$daemon/pid)"
      if ps -p $daemon_pid > /dev/null 2>&1; then
        local pid=$(cat $DAEMONIZE_WORK_DIR/$daemon/pid)
        local status="<green>running</><fade>, pid <bfade>$pid"
      else
        local status="<fade>not running</>"
      fi

      fade "daemon <bfade>$daemon</><fade> ($status)"
      tail -f $DAEMONIZE_WORK_DIR/$daemon/out
    fi
  done
}

function daemon_rm {

  if [[ ! -d $DAEMONIZE_WORK_DIR ]]; then
    error "No daemons running"
  fi

  for daemon in $( ls $DAEMONIZE_WORK_DIR ) ; do

    if [[ ${1:-} == $daemon ]] || [[ $(cat $DAEMONIZE_WORK_DIR/$daemon/pid) == ${1:-} ]]; then

      if daemon_is_running ${1:-} ; then
        error "Daemon is running, you must kill it first!"
      fi

      putz ""
      putz "Removing deamon <b>$daemon</>, pid <b>$(cat $DAEMONIZE_WORK_DIR/$daemon/pid)</>"
      rm -rf $DAEMONIZE_WORK_DIR/$daemon
      putz ""

    fi
  done
}

function daemon_is_running {
  if [[ ! -d $DAEMONIZE_WORK_DIR ]]; then
    return 1
  fi

  for daemon in $( ls $DAEMONIZE_WORK_DIR ) ; do
    if [[ ${1:-} == $daemon ]] || [[ $(cat $DAEMONIZE_WORK_DIR/$daemon/pid) == ${1:-} ]]; then
      if ps -p $(cat $DAEMONIZE_WORK_DIR/$daemon/pid) > /dev/null 2>&1 ; then
        return 0
      else
        return 1
      fi
    fi
  done

  return 1
}

function daemon_ls {

  local daemons="$( ls $DAEMONIZE_WORK_DIR )"

  if [[ -z "$daemons" ]]; then
    error "Non daemons running"
  fi

  putz ""

  for entry in $daemons ; do
    local entry="$DAEMONIZE_WORK_DIR/$entry"
    local daemon="${entry#$DAEMONIZE_WORK_DIR/}"

    local daemon_pid="$(cat $entry/pid)"
    if daemon_is_running $daemon; then
      local status="is <green>running</>, pid <b>$daemon_pid</>"
    else
      local status="<fade>not running</>, pid <b>$daemon_pid</>"
    fi

    local cmd="bash $H_RELATIVE_BIN $(cat $entry/args)"

    if [[ ${#cmd} -gt 72 ]]; then
      local cmd="${cmd:0:69}..."
    fi

    putz "<b>$daemon</> $status"
    putz " <fade>$cmd</>"
    putz ""
  done
}
