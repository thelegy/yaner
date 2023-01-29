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
  wat.thelegy.firewall.enable = true;
  wat.thelegy.hass.enable = true;
  wat.thelegy.hw-t410.enable = true;

  networking.nftables.firewall = {
    zones.hass = {
      ipv4Addresses = [ "192.168.1.30" ];
    };
    rules.hass-inbound = {
      from = "all";
      to = [ "hass" ];
      verdict = "accept";
    };
    rules.hass-outbound = {
      from = [ "hass" ];
      to = "all";
      verdict = "accept";
    };
  };

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

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", ATTRS{physical_location/horizontal_position}=="right", ATTRS{physical_location/vertical_position}=="lower", SYMLINK+="ender3s1"
  '';

  wat.thelegy.ender3s1 = {
    enable = true;
  };

})
