#!/usr/bin/env ash

# Install blowfish theme
git submodule update --init --recursive

# start hugo server
hugo server --environment production --bind 0.0.0.0 --port 1313 --watch
