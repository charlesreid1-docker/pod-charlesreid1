#!/bin/bash

for dir in `find * -maxdepth 0 -type d`; do
    ## Option 1: tedious
    #(
    #cd $dir
    #git checkout master
    #git pull origin master
    #)

    ## Option 2: slick
    #git submodule update --init --remote $dir

    # Option 3: best
    git submodule update --init --recursive
done

git commit -a -m 'Updating submodules to latest'
git push origin master

