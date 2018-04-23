#!/bin/bash

for dir in `/bin/ls -1 | /bin/grep "d-"`; do
    cd $dir
    git checkout master
    git pull origin master
    cd ..
done

git commit -a -m 'Updating submodules to latest'
git push origin master

