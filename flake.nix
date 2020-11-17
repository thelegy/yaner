{
  description = "Yet Another Nix Expression Repository";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
    nixpkgs-stable.url = github:NixOS/nixpkgs/nixos-20.09;
  };

  outputs = inputs@{self, ...}: let
    outputs = rec {
      lib = import (self + "/lib"); 

      overlay = import ./pkgs;
      nixosModules = lib.findNixosModules ./modules;

      nixosConfigurations = import self meta;
    };
    meta = inputs // outputs;
  in outputs;

}
