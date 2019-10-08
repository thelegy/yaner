
{
  #name = "yaner";

  description = "A flake for system configuration";

  epoch = 201909;

  outputs = { self, nixpkgs }: rec {

    nixosConfigurations = let
      devices = import ./default.nix;
      wrapConfig = device: nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          nixpkgs.nixosModules.notDetected
          ({ system.configurationRevision = self.rev;
            /* typical configuration.nix stuff follows */
          } // device {
            config = self.config;
            pkgs = nixpkgs.pkgs;
            lib = nixpkgs.lib;
          })
        ];
      };
    in
      builtins.mapAttrs (_: wrapConfig) devices;

  };

}
