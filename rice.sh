#!/bin/bash

sudo pacman -S archlinux-wallpaper

git clone https://github.com/addy-dclxvi/gtk-theme-collections

git clone https://github.com/addy-dclxvi/openbox-theme-collections

git clone https://github.com/caevee/.dotfiles

sudo mv ~/gtk-theme-collection/Lumiere /usr/share/themes/

sudo mv ~/openbox-theme-collection/Clia /usr/share/themes/

mkdir ~/Pictures
mkdir ~/wal

cp ~/.dotfiles/autumnanimegirl.jpg ~/Pictures/wal/autumnanimegirl.jpg

cd .dotfiles/

rm -r ~/.config/Thunar

stow .config/

rm ~/.viminfo

stow vim/

rm ~/.bashrc
rm ~/.bash_profile

stow bash

