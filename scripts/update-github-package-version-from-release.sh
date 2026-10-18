#!/bin/bash
set -e

PKGNAME="$1"
UPDATE_CHECKSUM="${UPDATE_CHECKSUM:-true}"
UPSTREAM_REPO="${UPSTREAM_REPO}" # Injected from matrix

echo "Updating $PKGNAME from upstream repo: $UPSTREAM_REPO..."

if [ -z "$UPSTREAM_REPO" ]; then
	echo "Error: UPSTREAM_REPO is not defined for this package."
	exit 1
fi

LATEST_TAG=$(curl -s "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" | jq -r .tag_name)

if [[ "$LATEST_TAG" == "null" || -z "$LATEST_TAG" ]]; then
	echo "Failed to fetch latest tag from $UPSTREAM_REPO."
	exit 1
fi

CLEAN_VER="${LATEST_TAG#v}"
NEW_VER="${CLEAN_VER//-/_}"
CURRENT_VER=$(grep '^pkgver=' PKGBUILD | cut -d'=' -f2)

echo "Latest: $NEW_VER | Current: $CURRENT_VER"

if [ "$NEW_VER" != "$CURRENT_VER" ]; then
	echo "New version found. Updating PKGBUILD..."

	sed -i "s/^pkgver=.*/pkgver=${NEW_VER}/" PKGBUILD
	sed -i "s/^pkgrel=.*/pkgrel=1/" PKGBUILD

	if [ "$UPDATE_CHECKSUM" = "true" ]; then
		echo "Updating checksums..."
		updpkgsums
	else
		echo "Skipping checksum update as configured."
	fi

	makepkg --printsrcinfo >.SRCINFO

else
	echo "Package is already up to date."
fi
