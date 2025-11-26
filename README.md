# Gemini CLI Nix Package

A Nix package for [Gemini CLI](https://github.com/google-gemini/gemini-cli), Google's AI assistant in your terminal.

## Usage

### Run directly
```bash
# Stable version
nix run github:iamruinous/gemini-cli-nix

# Preview version
nix run github:iamruinous/gemini-cli-nix#gemini-cli-preview
```

### Install in profile
```bash
# Stable version
nix profile install github:iamruinous/gemini-cli-nix

# Preview version
nix profile install github:iamruinous/gemini-cli-nix#gemini-cli-preview
```

### Use in flake
Add to your `flake.nix`:
```nix
{
  inputs.gemini-cli.url = "github:iamruinous/gemini-cli-nix";
  
  outputs = { self, nixpkgs, gemini-cli, ... }: {
    # ...
    environment.systemPackages = [
      gemini-cli.packages.${system}.default # or .gemini-cli
      # gemini-cli.packages.${system}.gemini-cli-preview
    ];
  };
}
```

## Maintenance

The packages are automatically updated via GitHub Actions.
To update manually:
```bash
# Update stable
./scripts/update-version.sh

# Update preview
./scripts/update-preview-version.sh
```