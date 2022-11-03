{ lib, mkTrivialModule, config, ... }:
with lib;

mkTrivialModule {

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [ { home.stateVersion = config.system.stateVersion; } ];
  };

}
