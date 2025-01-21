{ mkMachine, flakes, ... }:
mkMachine
  {
  }
  (
    {
      lib,
      pkgs,
      config,
      ...
    }:
    with lib;

    {

      system.stateVersion = "24.11";

      imports = [
        ./hardware-configuration.nix
        ./installer.nix
      ];

      hardware.cpu.amd.updateMicrocode = true;
      powerManagement.cpuFreqGovernor = "schedutil";

      wat.thelegy.base.enable = true;

      boot.initrd.availableKernelModules = [ "igc" ];
      boot.initrd.network.enable = true;
      boot.initrd.network.ssh = {
        enable = true;
        hostKeys = [ "/etc/secrets/initrd_ed25519_host_key" ];
      };

      boot.swraid.mdadmConf = ''
        MAILADDR admin@janbeinke.com
      '';

    }
  )
