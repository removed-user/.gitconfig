#!/bin/sh 
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")
URL=$(git -C "$SCRIPT_DIR" config get remote.origin.url)
PREV_DIR=$(pwd)

clean_dir() {
git reset --hard 
git clean -fd
git pull 
chmod +x setup.sh
}

set_env() {
[ -e "$HOME/.gitconfig" ] && mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"
}

relocate_self() {
if [ "$SCRIPT_DIR" != "$HOME/gitconfig" ];
then 
[ -e "$HOME/gitconfig" ] && rm -rf "$HOME/gitconfig"
git clone "$URL" "$HOME/gitconfig"
chmod +x "$HOME/gitconfig/setup.sh"
exec sh -c "$HOME/gitconfig/setup.sh"
fi 
}

ensure_paths() {
if [ "$SCRIPT_DIR" != "$HOME/.config/git" ];
then
[ -d "$HOME/.config/git" ] && rm -rf "$HOME/.config/git"
cp -r "$SCRIPT_DIR" "$HOME/.config/git"
[ ! -d "$HOME/.ssh" ] && mkdir "$HOME/.ssh"
fi
}


cd "$SCRIPT_DIR"
set_env
clean_dir
relocate_self
ensure_paths
cd "$PREV_DIR"
