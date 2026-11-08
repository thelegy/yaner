{ wat, ... }:
{
  flake.nixosModules.homeManager = wat.mkModule [ "homeManager" ] (
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
