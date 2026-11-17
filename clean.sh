#!/bin/sh 
set -e
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")

if [ ! -f "$SCRIPT_DIR/.clean" ];
then
cd "$SCRIPT_DIR"
git reset --hard 
git clean -fd
git pull 
chmod +x setup.sh
touch .clean
cd -
fi
