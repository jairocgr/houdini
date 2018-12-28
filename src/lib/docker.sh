#!/usr/bin/env bash

export DOCKER_CONFIG_TEMPLATE_DIR="$H_PROJECT_ROOT/docker/config/template"
export DOCKER_RUNNING_CONFIG_DIR="$H_PROJECT_ROOT/docker/config/running"
export DOCKER_RUNNING_DATA_DIR="$H_PROJECT_ROOT/docker/data"
export DOCKER_DEFAULT_RUNNING_CONTAINER="bctl"

function docker_assemble_config {

  src="$DOCKER_CONFIG_TEMPLATE_DIR/$1"
  dst="$DOCKER_RUNNING_CONFIG_DIR/$1"

  mkdir -p $(dirname "${dst}")

  echo -e "Assembling \"$dst\" from \"$src\"..."

  perl -p -e 's/\$\{([^}]+)\}/defined $ENV{$1} ? $ENV{$1} : $&/eg' < $src \
    | tee $dst > /dev/null
}

function docker_exists_running_config {
  [[ -f $DOCKER_RUNNING_CONFIG_DIR/$1 ]];
}

function inside_container {
  [[ -f /.dockerenv ]];
}

function container_is_running {
  docker_installed && docker ps -f status=running | grep $1 > /dev/null 2>&1
}

function containerize {

  if inside_container; then
    return
  fi

  container="${1:-$DOCKER_DEFAULT_RUNNING_CONTAINER}"

  if container_is_running $container; then
    docker exec -it $container /bin/bash $H_ID ${H_ARGS[@]}
    exit 0
  else
    die "Container $container not running!"
  fi
}

function docker_config_symlink {
  src="$DOCKER_RUNNING_CONFIG_DIR/$1"
  dst="$2"

  mkdir -p $(dirname "${dst}")

  echo -e "Symlinking \"$dst\" from \"$src\"..."
  rm -rf ${dst}
  ln -s $src $dst
}

function docker_exists_network {
  docker network list | grep -E ".+ ${1} .+" > /dev/null 2>&1
}

function docker_compose_echo {
  docker-compose --version
}

function docker_echo {
  docker --version
}

function docker_installed {
  command -v docker >/dev/null 2>&1
}

function docker_composer_installed {
  command -v docker-compose >/dev/null 2>&1
}

function require_docker {
  docker_installed || install_docker
}

function docker_full_installed {
  docker_installed && docker_composer_installed
}

function require_docker_composer {
  docker_composer_installed || install_docker_composer
}

function install_docker {
  if is_linux; then

    curl -fsSL get.docker.com | sudo sh

    sudo usermod -aG docker $USER

    if ! docker_installed; then
      die " Instalação do docker falhou!"
    fi

  else
    red ""
    red " Voce precisa instalar o docker e adicona-lo ao path na "
    red " sua maquina: https://docs.docker.com/engine/installation"
    red ""
    exit 1
  fi
}

function install_docker_composer {
  if is_linux; then

    sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) \
      -o /usr/local/bin/docker-compose

    sudo chmod +x /usr/local/bin/docker-compose

    if ! docker_composer_installed; then
      die " Instalação do docker-compose falhou!"
    fi

    docker-compose --version

  else
    red ""
    red " Voce precisa instalar o docker compose e adicona-lo ao path na "
    red " sua maquina: https://docs.docker.com/compose/install"
    red ""
    exit 1
  fi
}

function docker_caller_user {
  stat -c '%u' $H_DIR | tr -d '\n'
}
