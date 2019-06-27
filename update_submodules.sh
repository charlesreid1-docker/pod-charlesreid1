#!/bin/bash

GREP="`which grep`"

for dir in `find . -type d -maxdepth 1 | $GREP -v "docs" | $GREP -v ".git"`; do
    echo "--------------------"
    echo $dir
    (
    cd $dir
    git checkout master
    git pull gh master
    )
done

git commit -a -m 'Updating submodules to latest'
git push gh master

