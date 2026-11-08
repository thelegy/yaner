{ inputs, config, ... }:
{

  flake-file.inputs.wat.url = "github:thelegy/wat/rust";

  imports = [
    inputs.wat.flakeModules.default
  ];

  wat = {
    namespace = [ "thelegy" ];
    loadModules = [
      inputs.dms-plugin-registry.nixosModules.default
      inputs.homemanager.nixosModules.home-manager
      inputs.nix-index-database.nixosModules.nix-index
      inputs.nixos-nftables-firewall.nixosModules.default
      inputs.sops-nix.nixosModules.sops
    ];
  };

  flake = {
    overlay = import ../wat/overlay inputs;

    nixosConfigurations = config.wat.lib.findMachines ../wat/hosts;
  };
}
