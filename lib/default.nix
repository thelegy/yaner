let

  lib = (import ./helpers.nix lib) // {

    mkNixosModule = import ./mkNixosModule.nix lib;
    findNixosModules = import ./findNixosModules.nix lib;

  };

in lib
