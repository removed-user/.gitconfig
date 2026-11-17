#!/bin/sh 
set -e
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")

cd "$SCRIPT_DIR"
git reset --hard HEAD
git clean -fd
git pull 
chmod +x setup.sh
chmod +x clean.sh
cd -
