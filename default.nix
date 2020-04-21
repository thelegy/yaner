# entry point for machine configurations:
# (import <repo-path>).<netname>.configurations.<hostname>

with builtins;
let

  # helpers :: { *: ? }
  helpers = import ./helpers.nix;

  # machinesDir :: path
  machinesDir = ./machines;

  # machineNames :: [ string ]
  machineNames = with helpers; (readFilterDir (filterAnd [(not filterDirHidden) filterDirDirs]) machinesDir);

  # extraModules :: [ path ]
  extraModules = with helpers; map (module: ./modules + "/${module}") (readFilterDir (not filterDirHidden) ./modules);

  # channelsDir :: path
  channelsDir = ./channels;

  # allChannels :: { *: path }
  allChannels = with helpers; keysToAttrs (channelname: import (channelsDir + "/${channelname}") channelname) (readFilterDir (filterAnd [(not filterDirHidden) filterDirDirs]) channelsDir);

  # mkMachineChannel :: string -> path
  mkMachineChannel = name:
    (import (machinesDir + "/${name}/channel.nix")) allChannels;

  # machineChannels :: { *: path }
  machineChannels = helpers.keysToAttrs mkMachineChannel machineNames;

  # mkMachineConfig :: string -> system_configuration
  mkMachineConfig = with helpers; name:
    let
      path = machinesDir + "/${name}";
      machineConfigs = foldl' (x: y: x ++ maybeToList (toExistingPath y)) [] [
        (path + "/configuration.nix")
        (path + "/hardware-configuration.nix")
      ];
    in { pkgs, config, lib, ... }:

    {
      imports = machineConfigs ++ extraModules;

      _module.args.helpers = helpers;
      _module.args.channels = allChannels;

      nixpkgs.config = {
        packageOverrides = (import ./pkgs/all-packages.nix) { inherit lib config; };
      };

      nix.nixPath = [ "nixpkgs=${machineChannels.${name}}" ];

      networking.hostName = lib.mkDefault name;

    };

in
{

  # configurations :: { *: system_configuration }
  configurations = helpers.keysToAttrs mkMachineConfig machineNames;

  # channels :: { *: path }
  channels = machineChannels;

}
