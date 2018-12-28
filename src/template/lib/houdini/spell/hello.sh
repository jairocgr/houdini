#!/usr/bin/env bash

#
# Baixa e restaura dump
#
# USAGE
#   bash bin/syscor dump pull <dump> [dbname]
#
# ARGS
#   `dump`  Nome do dump a ser baixado e restaurado.
#
# OPTIONAL ARGS
#   `dbname` Nome do banco de dados que o dump será restaurado
#            (padrão: o mesmo nome do `dump`).
#
# EXAMPLES
#   Vaixar e restaurar um dump de produção denominado "mg20170603_production"
#   e restaura-lo no banco de dados de mesmo nome:
#
#     $ bash bin/syscor dump pull mg20170603_production
#
function __testt {
  hello_world
}

#
# USAGE
#   bash bin/syscor dump pull <dump> [dbname]
#
# DESCRIPTION
#   Baixa e restaura dump
#
# ARGS
#   dump    Nome do dump a ser baixado e restaurado.
#
# OPTIONAL ARGS
#   dbname  Nome do banco de dados que o dump será restaurado
#           (padrão: o mesmo nome do `dump`).
#
# EXEMPLOS
#   Vaixar e restaurar um dump de produção denominado "mg20170603_production"
#   e restaura-lo no banco de dados de mesmo nome:
#
#     $ bash bin/syscor dump pull mg20170603_production
#
function pop {
  puts "pop message <b>${1:-<empty>}</>"
}
