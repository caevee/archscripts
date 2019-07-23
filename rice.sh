#!/bin/bash

git clone https://github.com/caevee/.dotfiles  &

cd .dotfiles/ &

stow .config/ &

stow vim/ &

stow bash &

