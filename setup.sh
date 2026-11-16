#!/bin/sh 
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")
URL=$(git config get remote.origin.url)
pushd "$SCRIPT_DIR"

git reset --hard 
git clean -fd
git pull 

set_env() {
[ -e ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.bak
}

if [ "$SCRIPT_DIR" != "~/gitconfig" ];
then 
[ -e ~/gitconfig ] && rm -rf ~/gitconfig
mv "$SCRIPT_DIR" ~/gitconfig
exec sh -c ~/gitconfig/setup.sh
fi 

ensure_paths() {
[ -d ~/.config/git ] && rm -rf ~/.config/git
mv "$SCRIPT_DIR" ~/.config/git
[ ! -d ~/.ssh ] && mkdir ~/.ssh
}
ensure_paths
popd
