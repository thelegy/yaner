{ lib, mkTrivialModule, ... }:
with lib;

mkTrivialModule {

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

}
