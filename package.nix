{ lib
, stdenv
, fetchurl
, nodejs_22
, cacert
, bash
}: 

let
  version = "0.17.1"; # Update this to install a newer version

  # Pre-fetch the npm package as a Fixed Output Derivation
  # This allows network access during fetch phase for sandbox compatibility
  geminiCliTarball = fetchurl {
    url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
    # To get new hash when updating version:
    # nix-prefetch-url https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-VERSION.tgz
    sha256 = "6e506cba746f3f24ef9ed0d8847e07003f34852de759af1923191e0d2bc2d95b";
  };
in
stdenv.mkDerivation rec {
  pname = "gemini-cli";
  inherit version;

  # Don't try to unpack a source tarball - we'll handle it in buildPhase
  dontUnpack = true;

  # Build dependencies
  nativeBuildInputs = [
    nodejs_22   # Use Node.js v22 LTS for compatibility
    cacert      # SSL certificates for npm
  ];

  buildPhase = ''
    # Create a temporary HOME for npm to use during build
    export HOME=$TMPDIR
    mkdir -p $HOME/.npm

    # Configure npm to use Nix's SSL certificates
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    export NODE_EXTRA_CA_CERTS=$SSL_CERT_FILE

    # Tell npm where to find certificates
    ${nodejs_22}/bin/npm config set cafile $SSL_CERT_FILE

    # Configure npm to work offline


    # Install gemini-cli from the pre-fetched tarball
    # This avoids network access during build phase
    ${nodejs_22}/bin/npm install -g --prefix=$out ${geminiCliTarball}
  '';

  installPhase = ''
    # The npm-generated binary has issues with env and paths
    # Remove it so we can create our own wrapper
    rm -f $out/bin/gemini

    # Create a wrapper script that:
    # 1. Uses NODE_PATH to find modules without changing directory
    # 2. Runs gemini from the user's current directory
    # 3. Passes all arguments through
    # 4. Preserves the consistent path for settings
    mkdir -p $out/bin
    cat > $out/bin/gemini << 'EOF'
    #!${bash}/bin/bash
    # Set NODE_PATH to find the gemini-cli modules
    export NODE_PATH="$out/lib/node_modules"

    # Disable automatic update checks since updates should go through Nix
    export DISABLE_AUTOUPDATER=1

    # Create a temporary npm wrapper that Gemini CLI will use internally
    # This ensures it doesn't interfere with project npm versions
    export _GEMINI_NPM_WRAPPER="$(mktemp -d)/npm"
    cat > "$_GEMINI_NPM_WRAPPER" << 'NPM_EOF'
    #!${bash}/bin/bash
    # Intercept npm commands that might trigger update checks
    if [[ "$1" = "update" ]] || [[ "$1" = "outdated" ]] || [[ "$1" = "view" && "$2" =~ @google/gemini-cli ]]; then
        echo "Updates are managed through Nix. Current version: ${version}"
        exit 0
    fi
    # Pass through to bundled npm for other commands
    exec ${nodejs_22}/bin/npm "$@"
    NPM_EOF
    chmod +x "$_GEMINI_NPM_WRAPPER"

    # Only add our npm wrapper to PATH for Gemini CLI's internal use
    export PATH="$(dirname "$_GEMINI_NPM_WRAPPER"):$PATH"

    # Run gemini from current directory
    exec ${nodejs_22}/bin/node --no-warnings --enable-source-maps "$out/lib/node_modules/@google/gemini-cli/dist/index.js" "$@"
    EOF
    chmod +x $out/bin/gemini

    # Replace $out placeholder with the actual output path
    substituteInPlace $out/bin/gemini \
      --replace '$out' "$out"
  '';

  meta = with lib; {
    description = "Gemini CLI - AI assistant in your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20; # Gemini CLI is Apache-2.0 licensed
    platforms = platforms.all;
  };
}
