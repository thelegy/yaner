{ wat, ... }:
{
  flake.nixosModules.homeManager = wat.mkModuleWrapped [ "homeManager" ] (
    {
      cfg,
      lib,
      config,
      ...
    }:
    with lib;

    {

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        sharedModules = [ { home.stateVersion = config.system.stateVersion; } ];
      };

    }

  );
}
