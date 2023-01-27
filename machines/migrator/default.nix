{ mkMachine, ... }:

mkMachine {} ({ pkgs, config, ... }: let

  networkInterface = "enp0s25";
  macAddress = "f0:de:f1:04:c2:fc";

in {

  system.stateVersion = "22.11";

  wat.installer.btrfs = {
    enable = true;
    installDisk = "/dev/disk/by-id/ata-SanDisk_SDSSDP128G_141350402051";
    swapSize = "8GiB";
    bootloader = "grub";
  };

  wat.thelegy.base.enable = true;
  wat.thelegy.hw-t410.enable = true;
  wat.thelegy.hass.enable = true;

  services.openssh.forwardX11 = true;

  services.logind.lidSwitch = "ignore";

  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    netdevs.br0 = {
      netdevConfig = {
        Name = "br0";
        Kind = "bridge";
        MACAddress = macAddress;
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

  wat.thelegy.ender3s1 = {
    enable = true;
  };

})
