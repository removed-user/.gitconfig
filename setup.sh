#!/bin/sh 
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")
URL=$(git config get remote.origin.url)

[ -e ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.bak

ensure_paths() {
[ -d ~/.config/git ] && rm -rf ~/.config/git
cp -r ${SCRIPT_DIR} ~/.config/git
[ ! -d ~/.ssh ] && mkdir ~/.ssh
}

ensure_paths

