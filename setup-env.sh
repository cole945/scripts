
cp -n _tmux.conf ~/.tmux.conf
cp -n _vimrc ~/.vimrc
echo "source ~/repos/scripts/_bashrc.sh" >> ~/.bashrc

vim tmux git build-essential cgdb cmake
