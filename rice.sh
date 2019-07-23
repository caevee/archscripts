#!/bin/bash

git clone https://github.com/addy-dclxvi/gtk-theme-collections

git clone https://github.com/addy-dclxvi/openbox-theme-collections

git clone https://github.com/caevee/.dotfiles

sudo mv ~/gtk-theme-collections/Lumiere /usr/share/themes/

sudo mv ~/openbox-theme-collections/Clia /usr/share/themes/

mkdir ~/Pictures
mkdir ~/Pictures/wal

cp ~/.dotfiles/autumnanimegirl.jpg ~/Pictures/wal/autumnanimegirl.jpg

cd .dotfiles/

rm -r ~/.config/Thunar

stow .config/

rm ~/.viminfo

stow vim/

rm ~/.bashrc
rm ~/.bash_profile

stow bash
