#!/usr/bin/env bash

function hello {
  putz "hello <war>world</>"
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
function __ps {
  putz ""
  putz "Process table from <b>$HOSTNAME</b>/${1:-no_arg}"
  putz ""
  ps | indent
  putz ""
}

function ptable {
  cast sun ps
  cast sun dump list
}

#
# Mostra a table de processos do *host* atual
#
# USAGE
#   bash $H_RELATIVE_BIN sun ps
#
# OPTIONS
#  These options control whether output is written to file(s), standard output,
#  or directly to a man pager.
#
#   * -m, --man:
#     Don't generate files, display <file>s as if man(1) were invoked on the roff
#
function default {
  puts "statements <b>${@}</>"
}

#
# Run token server
#
function serve {
  putz ""
  putz "server test <b>$HOSTNAME:3000</>"
  while true; do
    putz " serving token $(openssl rand -base64 16 2> /dev/null)"
    sleep 5
  done
  putz ""
}
