#!/bin/sh
SCRIPT_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$SCRIPT_PATH")

[ ! -d ~/.config/git ] && mkdir -p ~/.config/git
