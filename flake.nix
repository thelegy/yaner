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

    nixos-nftables-firewall = {
      url = github:thelegy/nixos-nftables-firewall;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    queezle-dotfiles = {
      url = gitlab:jens/dotfiles?host=git.c3pb.de;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    qbar.url = gitlab:jens/qbar?host=git.c3pb.de;

    nixpkgs-stable.url = github:NixOS/nixpkgs/nixos-20.09;

    nixpkgs-staging-next.url = github:NixOS/nixpkgs/staging-next;

  };


  outputs = flakes@{ wat, ... }: wat.lib.mkWatRepo flakes ({ findModules, findMachines, ... }: rec {
    namespace = [ "thelegy" ];
    loadOverlays = [
      flakes.queezle-dotfiles.overlay
    ];
    loadModules = [
      flakes.homemanager.nixosModules.home-manager
      flakes.nixos-nftables-firewall.nixosModules.full
    ];
    outputs = {

      overlay = import ./pkgs flakes;

      nixosModules = findModules namespace ./modules;

      nixosConfigurations = findMachines ./machines;

    };
  });


}
