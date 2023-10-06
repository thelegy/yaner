{ mkMachine, ... }:

mkMachine {} ({ pkgs, config, ... }: let

  networkInterface = "enp2s0";
  macAddress = "7c:10:c9:b8:53:6d";

in {

  system.stateVersion = "22.11";

  imports = [
    ./hardware-configuration.nix
    ./audio.nix
  ];

  wat.installer.btrfs = {
    enable = true;
    installDisk = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_S5GXNX0W493233T";
    swapSize = "8GiB";
  };

  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  wat.thelegy.acme = {
    enable = true;
    staging = false;
    extraDomainNames = [
      "ha.0jb.de"
      "klipper.0jb.de"
    ];
  };
  wat.thelegy.base.enable = true;
  wat.thelegy.firewall.enable = true;
  wat.thelegy.hass.enable = true;
  wat.thelegy.nginx.enable = true;
  wat.thelegy.rtlan-net.enable = true;
  wat.thelegy.tailscale.enable = true;

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

  networking.nftables.firewall = {
    zones.hass-external = {
      ipv4Addresses = [ "192.168.1.30" ];
    };
    rules.hass-inbound = {
      from = "all";
      to = [ "hass-external" ];
      allowedTCPPorts = [ 22 ];
    };
    rules.hass-outbound = {
      from = [ "hass-external" ];
      to = "all";
      verdict = "accept";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", ENV{ID_PATH}=="pci-0000:05:00.4-usb-0:2:1.0", SYMLINK+="zigstar", GROUP="zigbee", ENV{SYSTEMD_WANTS}="ser2net-zigstar.service"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", ENV{ID_PATH}=="pci-0000:01:00.0-usb-0:1:1.0", SYMLINK+="ender3s1"
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
    # companionSerial = "/dev/klipper_companion";
  };

})
