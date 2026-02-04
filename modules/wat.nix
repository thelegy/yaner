{ inputs, ... }:
{

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

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
    outputs =
      { findModules, findMachines, ... }:
      {

        overlay = import ../wat/overlay inputs;

        nixosModules = findModules ../wat/modules;

        nixosConfigurations = findMachines ../wat/hosts;

      };
  };
}
