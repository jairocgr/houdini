#!/usr/bin/env bash

containerize

function __echo {
  puts "Echo inside container <b>${@}</>"
  puts "echo <b>$HOSTNAME</>"
  ls -lah
}
