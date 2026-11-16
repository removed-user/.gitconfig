#!/bin/sh
THIS_FILES_PATH=$(readlink -f -- "$0")
SCRIPT_DIR=$(dirname -- "$THIS_FILES_PATH")

ensure_paths() {
for dir in ~/.config/git ~/.ssh
do
[ ! -d $dir ] && mkdir -p $dir
done
}

check_repo_url() {
git remote -v
}

ensure_paths
check_repo_url
