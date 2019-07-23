#!/bin/bash

git clone https://github.com/caevee/.dotfiles

cd .dotfiles/

rm -r ~/.config/Thunar

stow .config/

rm ~/.viminfo

stow vim/

rm ~/.bashrc
rm ~/.bash_profile

stow bash

