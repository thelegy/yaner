{
  description = "Yet Another Nix Expression Repository";

  inputs = {

    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    homemanager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    queezle-dotfiles = {
      url = gitlab:jens/dotfiles?host=git.c3pb.de;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs-stable.url = github:NixOS/nixpkgs/nixos-20.09;

  };

  outputs = inputs@{self, nixpkgs, ...}: let
    outputs = rec {

      utils = import (self + "/utils") nixpkgs.lib;

      overlay = import ./pkgs;
      nixosModules = utils.findNixosModules {
        path = ./modules;
        namespace = [ "userconfig" "thelegy" ];
      };

      nixosConfigurations = import self meta;

    };
    meta = inputs // outputs;
  in outputs;

}
