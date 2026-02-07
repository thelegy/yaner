{ inputs, config, ... }:
{

  flake-file.inputs.wat = {
    url = "github:thelegy/wat/dendritic";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [
    inputs.wat.flakeModules.default
  ];

  wat = {
    namespace = [ "thelegy" ];
    loadModules = [
      inputs.homemanager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.nixos-nftables-firewall.nixosModules.default
      inputs.sops-nix.nixosModules.sops
    ];
  };

  flake = {
    overlay = import ../wat/overlay inputs;

    nixosModules = config.wat.lib.findModules ../wat/modules;

    nixosConfigurations = config.wat.lib.findMachines ../wat/hosts;
  };
}
