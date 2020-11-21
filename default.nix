meta:

with builtins;
let

  # machinesDir :: path
  machinesDir = ./machines;

  # machineNames :: [ string ]
  machineNames = with meta.lib; (readFilterDir (filterAnd [(not filterDirHidden) filterDirDirs]) machinesDir);

  layerPaths = with meta.lib; map (layer: ./layers + "/${layer}") (readFilterDir (not filterDirHidden) ./layers);

  # mkMachineArchitecture :: string -> string
  mkMachineArchitecture = name: with meta.lib;
    maybe "x86_64-linux" id (tryImport (machinesDir + "/${name}/system.nix"));

  mkMachinePkgs = name: with meta.lib;
    maybe meta.nixpkgs (pkgs: pkgs meta) (tryImport (machinesDir + "/${name}/pkgs.nix"));

  # evaluateConfig :: nixpkgs -> eval_config_args -> system_derivation
  evaluateConfig = pkgs: args: (import "${pkgs}/nixos/lib/eval-config.nix" args).config;

  # machineArchitectures :: { *: string }
  machineArchitectures = meta.lib.keysToAttrs mkMachineArchitecture machineNames;

  # mkMachineConfig :: nixpkgs -> string -> module
  mkMachineConfig = with meta.lib; pkgs: name:
    let
      path = machinesDir + "/${name}";
      machineConfigs = foldl' (x: y: x ++ maybeToList (toExistingPath y)) [] [
        (path + "/configuration.nix")
        (path + "/hardware-configuration.nix")
      ];
    in { config, lib, ... }:
    {
      imports = machineConfigs ++ (attrValues meta.nixosModules) ++ [
        meta.homemanager.nixosModules.home-manager
      ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };

      nixpkgs.overlays = [ meta.overlay ];

      _module.args.helpers = meta.lib;
      _module.args.isIso = mkDefault false;
      _module.args.meta = meta;

      system.configurationRevision = lib.mkIf (meta.self ? rev) meta.self.rev;
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

  # nixosConfigurations :: { *: system_derivation }
  nixosConfigurations = meta.lib.keysToAttrs mkMachineSystemDerivation machineNames;

in nixosConfigurations
