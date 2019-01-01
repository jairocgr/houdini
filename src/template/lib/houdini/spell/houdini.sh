#!/usr/bin/env bash

#
# RegExr was created by gskinner.com, and is proudly hosted by Media Temple.
#
function test {
  puts "test loopback \"${@:-<ZERO_ARGS}\""
}

function __default {
  echo "def"
}
