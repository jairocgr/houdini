#!/usr/bin/env bash
#
# Tarefas para a gerencia dos dumps de produção. These options control
# whether output is written to file(s), standard output, or directly
# to a man pager.
#

#
# Lista todos os dumps  disponíveis
#
# USAGE
#   bash bin/houdini sun/dump list
#
function list {
  ls -lah /var/log
}

#
# Lista todos os dumps  disponíveis
#
# USAGE
#   bash bin/houdini sun/dump list
#
function __ls {
  ls -lah /var/log
}

#
# Mostra a table de processos do *host* atual
#
# USAGE
#   bash $H_RELATIVE_BIN sun ps
#
# OPTIONS
#  These options control whether output is written to file(s), standard output, or
#  directly to a man pager.
#
#   * -m, --man:
#     Don't generate files, display <file>s as if man(1) were invoked on the roff
#     output file. This simulates default man behavior by piping the roff output
#     through groff(1) and the paging program specified by the MANPAGER
#     environment variable.
#
#   * -S, --server:
#     Don't generate files, start an HTTP server at <http://localhost:1207/> and
#     serve dynamically generated HTML for the set of input <file>s. A file named
#     *example.2.ronn* is served as */example.2.html*. There's also an index page
#     at the root with links to each <file>.
#
function __pop {
   echo "default ${@}"
}
