#!/usr/bin/env bash
set -euo pipefail

# Update Gemini CLI version in package.nix

echo "Checking for latest Gemini CLI version..."
LATEST_VERSION=$(npm view @google/gemini-cli version)
CURRENT_VERSION=$(grep 'version =' package.nix | cut -d '"' -f 2)

if [ "$LATEST_VERSION" == "$CURRENT_VERSION" ]; then
  echo "Already at latest version: $CURRENT_VERSION"
  exit 0
fi

echo "Updating from $CURRENT_VERSION to $LATEST_VERSION..."

URL="https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${LATEST_VERSION}.tgz"
SHA256=$(nix-prefetch-url $URL)

# Update package.nix
perl -pi -e "s/version = ".*"/version = "$LATEST_VERSION"/" package.nix
perl -pi -e "s/sha256 = ".*"/sha256 = "$SHA256"/" package.nix

echo "Updated package.nix to version $LATEST_VERSION"
