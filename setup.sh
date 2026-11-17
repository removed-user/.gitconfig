#!/bin/sh 
set -e
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")
URL=$(git -C "$SCRIPT_DIR" config get remote.origin.url)
PREV_DIR=$(pwd)

clean_dir() {
cd "$SCRIPT_DIR"
if [ ! -f ".clean" ]
git reset --hard 
git clean -fd
git pull 
chmod +x setup.sh
touch .clean
cd -
}

prevent_conflicts() {
[ -e "$HOME/.gitconfig" ] && mv "$HOME/.gitconfig" "$HOME/.gitconfig.bak"
}

relocate_self() {
    if [ "$SCRIPT_DIR" != "$HOME/gitconfig" ]; then
        [ -e "$HOME/gitconfig" ] && rm -rf "$HOME/gitconfig"
        
        if cp -r "$SCRIPT_DIR" "$HOME/gitconfig"; then
            chmod +x "$HOME/gitconfig/setup.sh"
            sh -c "$HOME/gitconfig/setup.sh"
        else
            echo "Error: Failed to move $SCRIPT_DIR to $HOME/gitconfig" >&2
            exit 1
        fi
    fi
}

ensure_paths() {
[ ! -d "$HOME/.config" ] && mkdir -p "$HOME/.config"
if [ "$SCRIPT_DIR" != "$HOME/.config/git" ];
then
[ -e "$HOME/.config/git" ] && rm -rf "$HOME/.config/git"
cp -r "$SCRIPT_DIR" "$HOME/.config/git"
[ ! -d "$HOME/.ssh" ] && mkdir "$HOME/.ssh"
fi
}


prevent_conflicts
clean_dir
relocate_self
ensure_paths
