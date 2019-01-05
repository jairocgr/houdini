#!/usr/bin/env bash
#
# *Ronn* converts textfiles to standard roff-formatted UNIX manpages or HTML.
# ronn-format(7) is based on markdown(7) but includes additional rules and syntax
# geared toward authoring manuals.
#
# In its default mode, `ronn` converts one or more input <file>s to HTML or roff
# output files. The `--roff`, `--html`, and `--fragment` options dictate which
# output files are generated. Multiple format arguments may be specified to
# generate multiple output files. Output files are named after and written to the
# same directory as input <file>s.
#
# The `--server` and `--man` options change the output behavior from file
# generation to serving dynamically generated HTML manpages or viewing <file> as
# with man(1).
#

#
# RegExr was created by gskinner.com, and is proudly hosted by Media Temple.
#
function test {
  puts "test loopback \"${@:-<ZERO_ARGS}\""
}

#
# Lorem ipsum dolor sit amet, consectetur
#
function ps {
  puts "list all mgr pocesses <b>database.production-link.com</>"
}

#
# The `--server` and `--man` options change the output behavior from file
#
function __default {
  echo "def"
}
