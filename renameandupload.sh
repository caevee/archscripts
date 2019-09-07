#!/bin/bash

cd ~/Backups/Packagelists

mv packagelist.txt packagelist.txt_$(date +%d%b%Y)

mv packagelistdesc.txt packagelistdesc.txt_$(date +%d%b%Y)

cd ~/Backups/

tar cvzf packagelists.tar.gz Packagelists

mv packagelists.tar.gz packagelists.tar.gz_$(date +%d%b%y)

gdrive upload packagelists.tar.gz_$(date +%d%b%y)

