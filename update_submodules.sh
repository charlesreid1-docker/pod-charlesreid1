#!/bin/bash

GREP="`which grep`"

for dir in `/bin/ls -1 | $GREP "d-"`; do
    cd $dir
    git checkout master
    git pull origin master
    cd ..
done

git commit -a -m 'Updating submodules to latest'
git push origin master

