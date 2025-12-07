{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  pkg-config,
  libsecret,
}:
buildNpmPackage rec {
  pname = "gemini-cli-preview";
  version = "0.20.0-preview.1";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "v${version}";
    hash = "sha256-KvjPT+ocuXgfvs3mIBbP9Vd+BcNHqy0gLEimLngh0CE=";
  };

  npmDepsHash = "sha256-Tb0DgFSHv6m0K0ARIbvEjTRB/6ytsbmFPDpv0lAve58=";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    libsecret
  ];

  postPatch = ''
    # Disable auto-update
    substituteInPlace packages/cli/src/utils/handleAutoUpdate.ts \
      --replace-fail "settings.merged.general?.disableAutoUpdate ?? false" "settings.merged.general?.disableAutoUpdate ?? true"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,share/gemini-cli}

    npm prune --omit=dev
    cp -r node_modules $out/share/gemini-cli/

    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server
    rm -f $out/share/gemini-cli/node_modules/@google/gemini-cli-test-utils
    rm -f $out/share/gemini-cli/node_modules/gemini-cli-vscode-ide-companion
    cp -r packages/cli $out/share/gemini-cli/node_modules/@google/gemini-cli
    cp -r packages/core $out/share/gemini-cli/node_modules/@google/gemini-cli-core
    cp -r packages/a2a-server $out/share/gemini-cli/node_modules/@google/gemini-cli-a2a-server

    ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini-preview
    chmod +x "$out/bin/gemini-preview"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Gemini CLI (Preview) - AI assistant in your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    platforms = platforms.all;
    mainProgram = "gemini-preview";
  };
}
