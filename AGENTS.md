# AGENTS.md - yaner Repository Guide

## Technology Stack
- **Language**: Nix (configuration management) with minimal JavaScript (DNSControl)
- **Framework**: `wat` (Nix deployment framework) + NixOS
- **Infrastructure**: NixOS configurations for multiple machines with secret management via sops-nix

## Build/Test/Deploy Commands
- **Build machine**: `nix build .#nixosConfigurations.<hostname>`
- **Deploy**: `deploy <switch|boot|reboot|test|dry-activate|build> <hostname>`
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
