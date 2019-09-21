
let
  # This function takes the path of a device module as an argument
  # and returns a complete module to be imported in configuration.nix
  makeDevice =
    devicePath:
    { config, pkgs, lib, ... }:

    {
      imports = [
        # ...the device module holding the system configuration...
        devicePath
      ] ++ (import ./modules/module-list.nix) lib; # ...and all the extra modules.

      nixpkgs.config = {
        packageOverrides = (import ./pkgs/all-packages.nix) lib;
      };

    };
  deviceModules =
    builtins.listToAttrs (map (deviceName: {
      name = deviceName;
      value = makeDevice (./devices + "/${deviceName}");
    }) (import ./devices/all-devices.nix));
in

deviceModules
