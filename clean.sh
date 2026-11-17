if [ ! -f "$SCRIPT_DIR/.clean" ];
then
cd "$SCRIPT_DIR"
git reset --hard 
git clean -fd
git pull 
chmod +x setup.sh
touch .clean
cd -
fi
