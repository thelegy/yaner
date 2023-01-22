{ mkMachine, ... }:

mkMachine {} ({ lib, pkgs, config, ... }: with lib; let

  networkInterface = "enp1s0";

  installDisk = "/dev/disk/by-id/ata-SanDisk_SDSSDP128G_141350402051";
  efiId = "CBC7-7164";
  luksUuid = "101359d3-6a37-4ad7-be51-e8335dd4046b";
  swapUuid = "d0b261e3-eb15-4778-8b5a-f9804a6ae02e";

in {

  system.stateVersion = "22.11";

  imports = [
    ./hardwareConfiguration.nix
  ];

  wat.thelegy.base.enable = true;
  wat.thelegy.hass.enable = true;

  services.openssh.forwardX11 = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  boot.initrd.availableKernelModules = [ "r8169" ];
  wat.thelegy.ssh-unlock = {
    enable = true;
    interface = networkInterface;
  };

  boot.initrd.luks.devices.migrator = {
    device = "/dev/disk/by-uuid/${luksUuid}";
    allowDiscards = true;
  };

  fileSystems."/" = {
    device = "/dev/mapper/vg_migrator-system";
    fsType = "bcachefs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/${efiId}";
    fsType = "vfat";
  };
  swapDevices = [
    {
      device = "/dev/mapper/vg_migrator-swap";
    }
  ];

  services.logind.lidSwitch = "ignore";

  networking.useDHCP = false;

  # Dnssec is currently broken
  # TODO: reasearch and fix the cause
  services.resolved.dnssec = "false";

  systemd.network = {
    enable = true;
    netdevs.br0 = {
      netdevConfig = {
        Name = "br0";
        Kind = "bridge";
        MACAddress = "3c:97:0e:4c:04:62";
      };
    };
    networks.${networkInterface} = {
      name = "${networkInterface}";
      bridge = [ "br0" ];
    };
    networks.br0 = {
      name = "br0";
      DHCP = "yes";
      extraConfig = ''
        [CAKE]
        Bandwidth =
      '';
    };
  };


})
