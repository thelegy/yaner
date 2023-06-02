{ mkMachine, ... }:

mkMachine {} ({ pkgs, config, ... }: let

  networkInterface = "enp0s25";
  macAddress = "f0:de:f1:04:c2:fc";

in {

  system.stateVersion = "22.11";

  imports = [
    ./audio.nix
  ];

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

  wat.thelegy.rtlan-net.enable = true;

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

  services.openssh.settings.X11Forwarding = true;

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
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", ATTRS{physical_location/horizontal_position}=="center", ATTRS{physical_location/vertical_position}=="lower", SYMLINK+="zigstar", GROUP="zigbee", ENV{SYSTEMD_WANTS}="ser2net-zigstar.service"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", ATTRS{physical_location/horizontal_position}=="right", ATTRS{physical_location/vertical_position}=="lower", SYMLINK+="ender3s1"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1d50", ATTRS{idProduct}=="614e", SYMLINK+="klipper_companion"
  '';

  users.groups.zigbee = {};

  systemd.services.ser2net-zigstar = let
    conf = pkgs.writeText "ser2net.yaml" ''
      connection: &con01
        accepter: tcp,20108
        connector: serialdev,/dev/zigstar,115200n81,local,dtr=off,rts=off
        options:
          kickolduser: true
    '';
  in {
    serviceConfig = {
      DynamicUser = true;
      Type = "simple";
      ExecStart = "${pkgs.ser2net}/bin/ser2net -d -u -c ${conf}";
      SupplementaryGroups = [ "zigbee" ];
    };
  };

  wat.thelegy.ender3s1 = {
    enable = true;
    companionSerial = "/dev/klipper_companion";
  };

})
