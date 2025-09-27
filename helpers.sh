#!/bin/bash

#       HELPERS.sh
#   -- a convenient script for handling alpine repos updating tasks --
#
#   usage: ./helpers.sh
#   arguments: --dir, --token

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --token)
            TOKEN="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

BUILD_DIR=${BUILD_DIR:-"*/"}

s_curl() {
    if [[ -n "$TOKEN" ]]; then
        curl -H "Authorization: Bearer $TOKEN" "$@"
    else
        curl "$@"
    fi
}

git pull

dirs=$(ls -d */ | sed 's:/$::')

packages_ok=()
packages_failed=()

for dir in $dirs; do
    if [ -f "$dir/APKBUILD" ]; then
        echo "✅ $dir: APKBUILD found, running..."
        cd "$dir" || exit 1

        NAME=$(grep '^pkgname=' APKBUILD | cut -d'=' -f2)
        VERSION=$(grep '^pkgver=' APKBUILD | cut -d'=' -f2)
        RELEASE_N=$(grep '^pkgrel=' APKBUILD | cut -d'=' -f2)
        SOURCE=$(sed -n 's/.*::\([^"]*\)/\1/p' APKBUILD | head -n 1)

        if [[ "$SOURCE" == *"github.com"* ]]; then
            user_repo=$(echo "$SOURCE" | sed 's|https://github.com/\([^/]*\)/\([^/]*\).*|\1/\2|')
            GITHUB=true
            echo "Repo: $user_repo"
        else
            echo "No GitHub URL found."
            GITHUB=false
        fi
        
        case $NAME in
            "minoplhy-gitea")
                user_repo="go-gitea/gitea"
            ;;
        esac

        if [[ $GITHUB == true ]]; then
            case $NAME in
                minoplhy-nginx*)
                    REPO_VERSION=$(s_curl -s "https://api.github.com/repos/$user_repo/releases" | jq -r '.[] | .tag_name' | grep -E '^alpine-nginx-release' | sort -V | tail -n 1 | sed 's/^alpine-nginx-release-//')
                ;;
                *)
                    REPO_VERSION=$(s_curl -s "https://api.github.com/repos/$user_repo/releases/latest" | jq -r '.tag_name' | sed 's/^v//')
                ;;
            esac
            if [[ $VERSION != $REPO_VERSION ]]; then
                sed -i "s/^pkgver=.*$/pkgver=$REPO_VERSION/" "APKBUILD"
                if [[ $RELEASE_N != 0 ]]; then
                    sed -i "s/^pkgrel=.*$/pkgrel=0/" "APKBUILD"
                fi
                echo "$NAME: pkgver updated to $REPO_VERSION in APKBUILD"
            elif [[ $VERSION == $REPO_VERSION ]]; then
                echo "$NAME: pkgver is up-to-date"
            else
                echo "$NAME: Internal Error!"
            fi
        fi

        cd ..
    else
        echo "⛔ $dir: No APKBUILD found, skipping."
    fi
done