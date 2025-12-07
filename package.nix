{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  pkg-config,
  libsecret,
}:
buildNpmPackage rec {
  pname = "gemini-cli";
  version = "0.19.4";

  src = fetchFromGitHub {
    owner = "google-gemini";
    repo = "gemini-cli";
    rev = "v${version}";
    hash = "sha256-kAb5CSD7PB3b63QnVSbgWxIMPO2Hh5LfmtZ3wE2TUFk=";
  };

  npmDepsHash = "sha256-tCu98oLr/xh4MJR6q+AbySHOmFeZFH7z59rL0K5A9Es=";

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

    ln -s $out/share/gemini-cli/node_modules/@google/gemini-cli/dist/index.js $out/bin/gemini
    chmod +x "$out/bin/gemini"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Gemini CLI - AI assistant in your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    platforms = platforms.all;
    mainProgram = "gemini";
  };
}
