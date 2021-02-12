{flakes, flakeOutputs}:

with builtins;
let

  # machinesDir :: path
  machinesDir = ./machines;

  # machineNames :: [ string ]
  machineNames = with flakeOutputs.utils; (readFilterDir (filterAnd [(not filterDirHidden) filterDirDirs]) machinesDir);

  layerPaths = with flakeOutputs.utils; map (layer: ./layers + "/${layer}") (readFilterDir (not filterDirHidden) ./layers);

  # mkMachineArchitecture :: string -> string
  mkMachineArchitecture = name: with flakeOutputs.utils;
    maybe "x86_64-linux" id (tryImport (machinesDir + "/${name}/system.nix"));

  mkMachinePkgs = name: with flakeOutputs.utils;
    maybe flakes.nixpkgs (pkgs: pkgs flakes) (tryImport (machinesDir + "/${name}/pkgs.nix"));

  # evaluateConfig :: nixpkgs -> eval_config_args -> system_derivation
  evaluateConfig = pkgs: args: (import "${pkgs}/nixos/lib/eval-config.nix" args).config;

  # machineArchitectures :: { *: string }
  machineArchitectures = flakeOutputs.utils.keysToAttrs mkMachineArchitecture machineNames;

  # mkMachineConfig :: nixpkgs -> string -> module
  mkMachineConfig = with flakeOutputs.utils; pkgs: name:
    let
      path = machinesDir + "/${name}";
      machineConfigs = foldl' (x: y: x ++ maybeToList (toExistingPath y)) [] [
        (path + "/configuration.nix")
        (path + "/hardware-configuration.nix")
      ];
    in { config, lib, ... }:
    {
      imports = machineConfigs ++ (attrValues flakeOutputs.nixosModules) ++ [
        flakes.homemanager.nixosModules.home-manager
        flakes.qd.nixosModules.qd
      ] ++ (attrValues flakes.queezle-dotfiles.nixosModules);

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
      };

      nixpkgs.overlays = [
        flakeOutputs.overlay
        flakes.queezle-dotfiles.overlay
        flakes.qd.overlay
      ];

      _module.args.helpers = flakeOutputs.utils;
      _module.args.isIso = mkDefault false;
      _module.args.flakes = flakes;
      _module.args.flakeOutputs = flakeOutputs;

      system.configurationRevision = lib.mkIf (flakes.self ? rev) flakes.self.rev;
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
  nixosConfigurations = flakeOutputs.utils.keysToAttrs mkMachineSystemDerivation machineNames;

in nixosConfigurations
