{
  description = "Nix package for Gemini CLI - AI assistant in your terminal";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        gemini-cli = final.callPackage ./package.nix {
          stdenv = prev.stdenv;
          fetchurl = prev.fetchurl;
          nodejs_22 = prev.nodejs_22;
          cacert = prev.cacert;
          bash = prev.bash;
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };
      in
      {
        packages = {
          default = pkgs.gemini-cli;
          gemini-cli = pkgs.gemini-cli;
        };

        apps = {
          default = {
            type = "app";
            program = "${pkgs.gemini-cli}/bin/gemini";
          };
          gemini-cli = {
            type = "app";
            program = "${pkgs.gemini-cli}/bin/gemini";
          };
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nixpkgs-fmt
            nix-prefetch-url
          ];
        };
      }) // {
        overlays.default = overlay;
      };
}
