#!/bin/bash

if ! git remote | grep -q up; then
    git remote add up https://github.com/sameersbn/docker-gitlab.git
fi
version="${1:-upstream}"
if [[ -z $SKIP ]]; then
    git checkout upstream
    git pull up master:upstream
    git checkout dev
fi
git rebase --autostash "$version"

git checkout --theirs .travis.yml
git add .travis.yml
git rebase --continue

git checkout --ours README.md

sed -i '1s|^.*$|[![](https://images.microbadger.com/badges/image/ustclug/gitlab.svg)](http://microbadger.com/images/ustclug/gitlab "Get your own image badge on microbadger.com")|
2s|^.*$|[![Build Status](https://travis-ci.org/ustclug/docker-gitlab.svg?branch=master)](https://travis-ci.org/ustclug/docker-gitlab)|
s|sameersbn/gitlab:|ustclug/gitlab:|
' README.md

git add README.md
git rebase --continue

echo Finished
