#!/bin/sh 
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")
URL=$(git config get remote.origin.url)

git reset --hard 
git clean -fd

[ -e ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.bak

if [ ${SCRIPT_DIR} == "~/.config/git" ];
then
mv ${SCRIPT_DIR} ~/gitconfig && exec -c ~/gitconfig/setup.sh
fi

ensure_paths() {
[ -d ~/.config/git ] && rm -rf ~/.config/git
mv ${SCRIPT_DIR} ~/.config/git
[ ! -d ~/.ssh ] && mkdir ~/.ssh
}
ensure_paths
