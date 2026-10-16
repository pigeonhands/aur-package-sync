#!/usr/bin/env bash
set -e

# Output CSV header to stdout
echo "pkg_name,upstream,full_ver,current_utc,status"

LEN=$(yq eval '.packages | length' packages.yml)

for ((i = 0; i < LEN; i++)); do
	PKG_NAME=$(yq eval ".packages[$i].name" packages.yml)
	UPSTREAM=$(yq eval ".packages[$i].upstream_repo" packages.yml)

	git clone --depth 1 https://aur.archlinux.org/${PKG_NAME}.git aur-temp-${PKG_NAME} 2>/dev/null

	if [ -f "aur-temp-${PKG_NAME}/PKGBUILD" ]; then
		PKG_VER=$(grep '^pkgver=' aur-temp-${PKG_NAME}/PKGBUILD | cut -d'=' -f2)
		PKG_REL=$(grep '^pkgrel=' aur-temp-${PKG_NAME}/PKGBUILD | cut -d'=' -f2)
		FULL_VER="${PKG_VER}-${PKG_REL}"
	else
		FULL_VER="Unknown"
	fi

	rm -rf aur-temp-${PKG_NAME}

	SAVED_VER=""
	SAVED_TIME=""

	TARGET_DIR="${VERSION_DIR:-package_versions}"
	VERSION_FILE="$TARGET_DIR/$PKG_NAME"

	if [ -f "$VERSION_FILE" ]; then
		SAVED_VER=$(grep '^PKG_VER=' "$VERSION_FILE" | cut -d'=' -f2- | tr -d '"')
		SAVED_TIME=$(grep '^LAST_UPDATED_UTC=' "$VERSION_FILE" | cut -d'=' -f2- | tr -d '"')
	fi

	ISO_NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

	if [ "$SAVED_VER" != "$FULL_VER" ]; then
		if [ -z "$SAVED_VER" ]; then
			STATUS="Initialized"
		else
			STATUS="Updated"
		fi
		CURRENT_UTC="$ISO_NOW"
	else
		STATUS="No Update"
		CURRENT_UTC="$SAVED_TIME"
		if [ -z "$CURRENT_UTC" ]; then
			CURRENT_UTC="$ISO_NOW"
		fi
	fi

	if [ -n "$VERSION_DIR" ]; then
		mkdir -p "$VERSION_DIR"
		cat <<EOF >"$VERSION_DIR/$PKG_NAME"
PKG_NAME="$PKG_NAME"
UPSTREAM="$UPSTREAM"
PKG_VER="$FULL_VER"
LAST_UPDATED_UTC="$CURRENT_UTC"
STATUS="$STATUS"
EOF
	fi

	echo "${PKG_NAME},${UPSTREAM},${FULL_VER},${CURRENT_UTC},${STATUS}"
done
