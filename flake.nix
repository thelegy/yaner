{

  description = "Yet Another Nix Expression Repository";


  inputs = {

    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;

    wat = {
      url = github:thelegy/wat;
      inputs.nixpkgs.follows = "nixpkgs";
    };

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


  outputs = flakes@{ wat, ... }: wat.lib.mkWatRepo flakes ({ findModules, findMachines, ... }: rec {
    loadOverlays = [
      flakes.queezle-dotfiles.overlay
    ];
    loadModules = [
      flakes.homemanager.nixosModules.home-manager
    ];
    outputs = {

      overlay = import ./pkgs;

      nixosModules = findModules ["thelegy"] ./modules;

      nixosConfigurations = findMachines ./machines;

    };
  });


}
