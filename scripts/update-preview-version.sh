#!/usr/bin/env bash
set -euo pipefail

# Update Gemini CLI Preview version in package-preview.nix

echo "Checking for latest Gemini CLI Preview version..."
# Get the version from the 'preview' dist-tag
LATEST_VERSION=$(npm view @google/gemini-cli dist-tags.preview)
CURRENT_VERSION=$(grep 'version =' package-preview.nix | cut -d '"' -f 2)

if [ "$LATEST_VERSION" == "$CURRENT_VERSION" ]; then
  echo "Already at latest preview version: $CURRENT_VERSION"
  exit 0
fi

echo "Updating from $CURRENT_VERSION to $LATEST_VERSION..."

URL="https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${LATEST_VERSION}.tgz"
SHA256=$(nix-prefetch-url $URL)

# Update package-preview.nix
perl -pi -e "s/version = ".*"/version = "$LATEST_VERSION"/" package-preview.nix
perl -pi -e "s/sha256 = ".*"/sha256 = "$SHA256"/" package-preview.nix

echo "Updated package-preview.nix to version $LATEST_VERSION"
