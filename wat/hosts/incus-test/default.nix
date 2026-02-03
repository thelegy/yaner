{ mkMachine, ... }:
mkMachine { } (
  {
    lib,
    config,
    pkgs,
    ...
  }:
  let
    networkInterface = "enp0s25";
    macAddress = "f0:de:f1:04:c2:fc";
  in
  {
    system.stateVersion = "24.11";

    imports = [
      ./hardware-configuration.nix
    ];

    wat.installer.btrfs = {
      enable = true;
      installDisk = "/dev/disk/by-id/ata-HITACHI_HTS722016K9SA00_080910DP0D70DVGTVRVC";
      swapSize = "8GiB";
      bootloader = "grub";
      installDiskIsSSD = false;
    };

    wat.thelegy.base.enable = true;

    # networking.useDHCP = false;
    #
    # systemd.network = {
    #   enable = true;
    #   netdevs.br0 = {
    #     netdevConfig = {
    #       Name = "br0";
    #       Kind = "bridge";
    #       MACAddress = macAddress;
    #     };
    #   };
    #   networks.${networkInterface} = {
    #     name = "${networkInterface}";
    #     bridge = ["br0"];
    #   };
    #   networks.br0 = {
    #     name = "br0";
    #     DHCP = "yes";
    #     extraConfig = ''
    #       [CAKE]
    #       Bandwidth =
    #     '';
    #   };
    # };

    systemd.services.k3s.path = [ pkgs.iptables-nftables-compat ];

    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = [
        "--disable=traefik"
      ];
      gracefulNodeShutdown = {
        enable = true;
      };
    };

    #boot.blacklistedKernelModules = ["ip_tables" "iptable_filter" "iptable_nat" "x_tables"];
    #boot.extraModprobeConfig = ''
    #  alias ip_tables off
    #'';

    networking.nftables.firewall.zones.elsewhere = {
      ipv4Addresses = [ "0.0.0.0/0" ];
      ipv6Addresses = [ "::/0" ];
    };
    networking.nftables.firewall.rules.fwd = {
      to = "all";
      from = "all";
      verdict = "accept";
    };

    networking.firewall.allowedTCPPorts = [
      9999
      9443
      6443
      443
    ];

    virtualisation.podman.enable = true;

    #virtualisation.incus = {
    #  enable = true;
    #  ui.enable = true;
    #  preseed = {
    #    config = {
    #      "core.https_address" = "0.0.0.0:9999";
    #      "images.auto_update_interval" = 6;
    #    };
    #    storage_pools = [
    #      {
    #        name = "local-btrfs";
    #        driver = "btrfs";
    #        config.source = "/srv/incus-pool-btrfs";
    #      }
    #    ];
    #  };
    #};
  }
)
