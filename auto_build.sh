#!/usr/bin/env bash

# requires apt package inotify-tools

inotifywait -r -m -e modify src |
    while read file_path file_event file_name; do
        cyan build
    done

