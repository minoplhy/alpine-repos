#!/bin/bash

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            DIR="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

DIR=${DIR:-"./"}
cd $DIR

for pkg in $(ls *-*-r*.apk | sed -E 's/(-[0-9]+\.[0-9]+\.[0-9]+-r[0-9]+)\.apk//'); do
    files_to_keep=$(ls ${pkg}-*-r*.apk | grep -Eo "${pkg}-[0-9]+\.[0-9]+\.[0-9]+-r[0-9]+" | sort -V | tail -n 2)
    files_to_delete=$(ls ${pkg}-*-r*.apk | grep -Eo "${pkg}-[0-9]+\.[0-9]+\.[0-9]+-r[0-9]+" | sort -V | head -n -2)
    for file in $files_to_delete; do
        echo "Removing: $file.apk"
        rm $file.apk
    done
done