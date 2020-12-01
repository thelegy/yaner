lib:

let

  utils = (import ./helpers.nix { inherit lib utils; }) // {

    mkNixosModule = import ./mkNixosModule.nix { inherit lib utils; };
    findNixosModules = import ./findNixosModules.nix { inherit lib utils; };

  };

in utils
