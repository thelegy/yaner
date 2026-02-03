{ inputs, ... }:
{

  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  flake = inputs.wat.lib.mkWatRepo inputs (
    {
      findModules,
      findMachines,
      ...
    }:
    rec {
      namespace = [ "thelegy" ];
      loadOverlays = [
        inputs.nix-index-database.overlays.nix-index
        inputs.nixGL.overlays.default
      ];
      loadModules = [
        inputs.homemanager.nixosModules.home-manager
        inputs.nix-index-database.nixosModules.nix-index
        inputs.nixos-nftables-firewall.nixosModules.default
        inputs.sops-nix.nixosModules.sops
      ];
      outputs = {

        overlay = import ../wat/overlay inputs;

        nixosModules = findModules namespace ../wat/modules;

        nixosConfigurations = findMachines ../wat/hosts;

        packages = inputs.wat.lib.withPkgsForLinux inputs.nixpkgs [ inputs.self.overlay ] (pkgs: {

        });

      };
    }
  );
}
