#!/usr/bin/env bash
#
# Gerencia as tarefas de background (daemons) em execução
#

#
# Lista todos as tarefas de background
#
function __ls {
  daemonizer ls ${@}
}

#
# Mostra a saída do daemon
#
# USAGE
#  houdini daemon tail <pid>
#
# ARGUMENTS
#  `pid` O pid ou o nome do daemon para mostrar a saída
#
function __tail {
  daemonizer tail ${@}
}

#
# Mostra o status do daemon
#
# USAGE
#  houdini daemon status <pid>
#
# ARGUMENTS
#  `pid` O pid ou o nome do daemon
#
function __status {
  daemonizer status ${@}
}

#
# Remove o daemon se ele já estiver parado
#
# USAGE
#  houdini daemon rm <pid>
#
# ARGUMENTS
#  `pid` O pid ou o nome do daemon
#
function __rm {
  daemonizer rm ${@}
}

#
# Mara a execução do daemon
#
# USAGE
#  houdini daemon kill <pid>
#
# ARGUMENTS
#  `pid` O pid ou o nome do daemon
#
function __kill {
  daemonizer kill ${@}
}

#
# Atalho para a ls
#
function __default {
  cast daemon ls
}
