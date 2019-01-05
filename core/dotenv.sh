#!/usr/bin/env bash

readonly ENV_FILE="$H_PROJECT_ROOT/.env"

function missing_dotenv_file {
  ! has_dotenv_file
}

function has_dotenv_file {
  [[ -f "$ENV_FILE" ]]
}

function has_dotenv_template_file {
  [[ -r $ENV_FILE.example ]]
}

function generate_dotenv_file {
  cp $ENV_FILE.example $ENV_FILE
}

function try_load_dotenv {

  if ! has_dotenv_file; then
    if has_dotenv_template_file; then
      generate_dotenv_file
    fi
  fi

  if has_dotenv_file; then
    load_dotenv
  fi
}

function load_dotenv {

  [[ -r "$ENV_FILE" ]] || die "Missing \"$ENV_FILE\" to be loaded"

  source $ENV_FILE
  set -a
  . $ENV_FILE
  set +a
}

try_load_dotenv
