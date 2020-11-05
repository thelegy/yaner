inputs@{ nixpkgs, ... }:

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

  # mkMachineArchitecture :: string -> string
  mkMachineArchitecture = name: with helpers;
    maybe "x86_64-linux" id (tryImport (machinesDir + "/${name}/system.nix"));

  mkMachinePkgs = name: with helpers;
    maybe nixpkgs (pkgs: pkgs inputs) (tryImport (machinesDir + "/${name}/pkgs.nix"));

  # evaluateConfig :: nixpkgs -> eval_config_args -> system_derivation
  evaluateConfig = pkgs: args: (import "${pkgs}/nixos/lib/eval-config.nix" args).config;

  # machineArchitectures :: { *: string }
  machineArchitectures = helpers.keysToAttrs mkMachineArchitecture machineNames;

  # mkMachineConfig :: nixpkgs -> string -> module
  mkMachineConfig = with helpers; pkgs: name:
    let
      path = machinesDir + "/${name}";
      machineConfigs = foldl' (x: y: x ++ maybeToList (toExistingPath y)) [] [
        (path + "/configuration.nix")
        (path + "/hardware-configuration.nix")
      ];
    in { config, lib, ... }:
    {
      imports = machineConfigs ++ extraModules;

      _module.args.helpers = helpers;
      _module.args.isIso = mkDefault false;

      nixpkgs.config = {
        packageOverrides = (import ./pkgs/all-packages.nix) { inherit lib config; };
      };

      nix.nixPath = [ "nixpkgs=${pkgs}" ];
      nix.registry.nixpkgs.flake = pkgs;

      networking.hostName = lib.mkDefault name;
    };

  # mkAdditionalIsoConfig :: string -> module
  mkAdditionalIsoConfig = name: { config, modulesPath, ... }: {
    imports = [
      "${modulesPath}/installer/cd-dvd/iso-image.nix"
      "${modulesPath}/profiles/all-hardware.nix"
      "${modulesPath}/profiles/base.nix"
    ];
    isoImage.isoName = "${config.isoImage.isoBaseName}-${config.system.nixos.label}-isohost-${name}.iso";
    isoImage.volumeID = substring 0 11 "NIXOS_ISO";
    isoImage.makeEfiBootable = true;
    isoImage.makeUsbBootable = true;
    boot.loader.grub.memtest86.enable = true;
    _module.args.isIso = true;
  };

  # mkAdditionalSdCardConfig :: string -> module
  mkAdditionalSdCardConfig = name: { config, modulesPath, ... }: {
    imports = [
      "${modulesPath}/installer/cd-dvd/sd-image.nix"
      "${modulesPath}/profiles/all-hardware.nix"
      "${modulesPath}/profiles/base.nix"
    ];
    sdImage.populateRootCommands = "";
    sdImage.populateFirmwareCommands = "";
    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    _module.args.isIso = true;
  };

  # mkMachineSystemDerivation :: string -> system_derivation
  mkMachineSystemDerivation = name:
    let
      pkgs = mkMachinePkgs name;
      configuration = mkMachineConfig pkgs name;
      system = mkMachineArchitecture name;
      iso = (evaluateConfig pkgs {
        inherit system;
        modules = [
          configuration
          (mkAdditionalIsoConfig name)
        ];
      }).system.build.isoImage;
      sdImage = (evaluateConfig pkgs {
        inherit system;
        modules = [
          configuration
          (mkAdditionalSdCardConfig name)
        ];
      }).system.build.sdImage;
    in pkgs.lib.nixosSystem {
      inherit system;
      modules = [
        configuration
        {
          system.build = {
            inherit iso sdImage;
          };
        }
      ];
    };

  # systems :: { *: system_derivation }
  systems = helpers.keysToAttrs mkMachineSystemDerivation machineNames;

in systems
