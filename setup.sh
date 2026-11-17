#!/bin/sh 
set -e
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")
PREV_DIR=$(pwd)

[ -e "$HOME/.gitconfig" ] && mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"


[ ! -d "$HOME/.ssh" ] && mkdir "$HOME/.ssh"
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
if [ "$SCRIPT_DIR" != "$HOME/.config/git" ];
then
rm -rf "$HOME/.config/git" || true
mkdir -p "$HOME/.config/git"
fi

cd "$SCRIPT_DIR"
git init --separate-git-dir "$HOME/.config/git/.git"
cd "$HOME/.config/git"
git reset --hard HEAD
git pull
