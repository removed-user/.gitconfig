#!/bin/sh 
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")
URL=$(git config get remote.origin.url)
PREV_DIR=$(pwd)

clean_dir() {
git reset --hard 
git clean -fd
git pull 
chmod +x setup.sh
}

set_env() {
[ -e ~/.gitconfig ] && mv ~/.gitconfig ~/.gitconfig.bak
}

relocate_self() {
if [ "$SCRIPT_DIR" != "~/gitconfig" ];
then 
[ -e ~/gitconfig ] && rm -rf ~/gitconfig
mv "$SCRIPT_DIR" ~/gitconfig
chmod +x ~/gitconfig/setup.sh
exec sh -c ~/gitconfig/setup.sh
fi 
}

ensure_paths() {
if [ "$SCRIPT_DIR" != ~/.config/git ];
then
[ -d ~/.config/git ] && rm -rf ~/.config/git
cp -r "$SCRIPT_DIR" ~/.config/git
[ ! -d ~/.ssh ] && mkdir ~/.ssh
fi
}


cd "$SCRIPT_DIR"
set_env
clean_dir
relocate_self
ensure_paths
cd "$PREV_DIR"
