{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-20.09";
  };

  outputs = inputs@{ ... }: {

    nixosConfigurations = import ./default.nix inputs;

  };
}
