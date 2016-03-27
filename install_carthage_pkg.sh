#!/bin/bash
# Install binary Carthage package at Travis-CI
# Thanks to http://ppinera.es/2015/12/29/install-last-carthage-ci.html

if [[ $# -eq 0 ]] ; then
    echo "Carthage version required"
    exit 1
fi

curl -OlL "https://github.com/Carthage/Carthage/releases/download/$1/Carthage.pkg"
sudo installer -pkg "Carthage.pkg" -target /
rm "Carthage.pkg"
