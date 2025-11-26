# Gemini CLI Nix Package

A Nix package for [Gemini CLI](https://github.com/google-gemini/gemini-cli), Google's AI assistant in your terminal.

## Usage

### Run directly
```bash
nix run github:iamruinous/gemini-cli-nix
```

### Install in profile
```bash
nix profile install github:iamruinous/gemini-cli-nix
```

### Use in flake
Add to your `flake.nix`:
```nix
{
  inputs.gemini-cli.url = "github:iamruinous/gemini-cli-nix";
  
  outputs = { self, nixpkgs, gemini-cli, ... }: {
    # ...
    environment.systemPackages = [
      gemini-cli.packages.${system}.default
    ];
  };
}
```

## Maintenance

The package is automatically updated via GitHub Actions.
To update manually:
```bash
./scripts/update-version.sh
```