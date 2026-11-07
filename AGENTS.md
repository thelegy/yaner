# AGENTS.md - yaner Repository Guide

## Technology Stack
- **Language**: Nix (configuration management) with minimal JavaScript (DNSControl)
- **Framework**: `wat` (Nix deployment framework) + NixOS
- **Infrastructure**: NixOS configurations for multiple machines with secret management via sops-nix

## Build/Test/Deploy Commands
- **Build machine**: `nix develop -c wat build <hostname>`
- **Deploy**: `nix develop -c wat <switch|boot|reboot|test|dry-activate> <hostname>`
- **wat CLI**: Use `wat` for builds and deployments. Run it via `nix develop -c wat` to make the development shell tools available. Bare `wat` commands work when direnv has already loaded the development shell.
- **All hosts**: Pass `--all` (`-A`) to operate on all hosts in the flake, for example `nix develop -c wat build --all`.
- **Replay files**: wat records runs in `.wat/logs/wat-events-*.jsonl` for later replay and analysis. The recording path is printed when a run starts.
- **Format code**: `treefmt` (RFC-style Nix formatting)
- **DNS preview**: `./bin/dnscontrol preview` (ALWAYS preview before push)
- **DNS deploy**: `./bin/dnscontrol push`
- **Development shell**: `nix develop` (exposes wat tools)

## Code Style Guidelines
- **Imports**: Standard function signature `{ lib, config, pkgs, ... }:` with `with lib;`
- **Formatting**: RFC-style Nix formatting via treefmt
- **Modules**: Use `mkTrivialModule` for simple modules, structured attribute sets
- **Naming**: Use kebab-case for files/directories, camelCase for Nix attributes
- **Error handling**: Use `mkDefault` for overridable defaults, explicit assertions where needed
- **Secrets**: Store in `secrets/` with sops encryption, reference via `config.sops`

## Repository Structure
- `machines/`: Per-host NixOS configurations
- `modules/`: Reusable NixOS modules
- `pkgs/`: Custom package definitions and overlays
- `secrets/`: SOPS-encrypted secrets and GPG keys
- `dns/`: DNSControl configuration and credentials
