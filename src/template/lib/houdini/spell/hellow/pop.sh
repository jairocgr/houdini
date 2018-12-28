#!/usr/bin/env bash
#
# <b>USAGE</>
#   bash bin/syscor dump pull <dump> [dbname]
#
# <b>DESCRIPTION</>
#   Baixa e restaura dump
#
# <b>ARGS</>
#   dump    Nome do dump a ser baixado e restaurado.
#
# <b>OPTIONAL ARGS</>
#   dbname  Nome do banco de dados que o dump será restaurado
#           (padrão: o mesmo nome do `dump`).
#
# <b>EXEMPLOS</>
#   Vaixar e restaurar um dump de produção denominado "mg20170603_production"
#   e restaura-lo no banco de dados de mesmo nome:
#
#     $ bash bin/syscor dump pull mg20170603_production
#

puts "pop message <b>${1:-<empty>}</>"
