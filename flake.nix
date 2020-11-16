{
  description = "Yet Another Nix Expression Repository";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    nixpkgs-stable.url = github:NixOS/nixpkgs/nixos-20.09;
  };

  outputs = inputs@{ ... }: let
    plumbing = import ./default.nix inputs;
  in {

    inherit (plumbing) nixosConfigurations nixosModules overlay;

  };
}
