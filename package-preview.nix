{ lib
, stdenv
, fetchurl
, nodejs_22
, cacert
, bash
}: 

let
  version = "0.19.0-preview.0"; # Update this to install a newer version

  # Pre-fetch the npm package as a Fixed Output Derivation
  geminiCliTarball = fetchurl {
    url = "https://registry.npmjs.org/@google/gemini-cli/-/gemini-cli-${version}.tgz";
    sha256 = "ad75fc297572c0654f93992e279510b24ddba48e25ed8bcc3e6d5657b0da1ca1";
  };
in
stdenv.mkDerivation rec {
  pname = "gemini-cli-preview";
  inherit version;

  dontUnpack = true;

  nativeBuildInputs = [
    nodejs_22
    cacert
  ];

  buildPhase = ''
    export HOME=$TMPDIR
    mkdir -p $HOME/.npm
    export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
    export NODE_EXTRA_CA_CERTS=$SSL_CERT_FILE
    ${nodejs_22}/bin/npm config set cafile $SSL_CERT_FILE

    # Install gemini-cli
    ${nodejs_22}/bin/npm install -g --prefix=$out ${geminiCliTarball}
  '';

  installPhase = ''
    # Remove the npm-generated link (it's named gemini by default)
    rm -f $out/bin/gemini

    mkdir -p $out/bin
    cat > $out/bin/gemini-preview << 'EOF'
    #!${bash}/bin/bash
    export NODE_PATH="$out/lib/node_modules"
    export DISABLE_AUTOUPDATER=1
    export _GEMINI_NPM_WRAPPER="$(mktemp -d)/npm"
    cat > "$_GEMINI_NPM_WRAPPER" << 'NPM_EOF'
    #!${bash}/bin/bash
    if [[ "$1" = "update" ]] || [[ "$1" = "outdated" ]] || [[ "$1" = "view" && "$2" =~ @google/gemini-cli ]]; then
        echo "Updates are managed through Nix. Current version: ${version}"
        exit 0
    fi
    exec ${nodejs_22}/bin/npm "$@"
    NPM_EOF
    chmod +x "$_GEMINI_NPM_WRAPPER"
    export PATH="$(dirname "$_GEMINI_NPM_WRAPPER"):$PATH"

    exec ${nodejs_22}/bin/node --no-warnings --enable-source-maps "$out/lib/node_modules/@google/gemini-cli/dist/index.js" "$@"
    EOF
    chmod +x $out/bin/gemini-preview

    substituteInPlace $out/bin/gemini-preview \
      --replace '$out' "$out"
  '';

  meta = with lib; {
    description = "Gemini CLI (Preview) - AI assistant in your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
