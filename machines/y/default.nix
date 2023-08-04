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

  wat.thelegy.base.enable = true;
  wat.thelegy.firewall.enable = true;
  wat.thelegy.rtlan-net.enable = true;

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

})
