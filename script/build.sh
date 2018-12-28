#!/usr/bin/env bash

SCRIPT_PATH="$(realpath ${BASH_SOURCE[0]})"
PROJECT_ROOT="$(realpath $(dirname $SCRIPT_PATH)/../)"

cd $PROJECT_ROOT

readonly BUILD_DIR="local/build"
readonly SRC_DIR="$PROJECT_ROOT/src"

rm -rf $BUILD_DIR

mkdir -p $BUILD_DIR/bin

cp -raf $SRC_DIR/template/. $BUILD_DIR

while read line; do
  if [[ "$line" =~ \#\!include.* ]]; then

    dir="$(echo $line | cut -d' ' -f2)"

    for file in $(find $SRC_DIR/$dir -name '*.sh'); do
      echo "# included from $file"
      echo "source $file"
      echo ""
      # echo "$(cat $file | sed -r '/^\#\!\/.*/d' | sed -r '/^$/d')"
    done

  else
    echo "$line"
  fi
done < src/bin/houdini > $BUILD_DIR/bin/houdini
