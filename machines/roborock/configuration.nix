{ lib, config, options, pkgs, ... }:
with lib;

{

  imports = [
    ./hardware-configuration.nix
  ];
  userconfig.thelegy.base.enable = true;

  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.useDHCP = false;

  systemd.network = {
    enable = true;
    netdevs.internal = {
      netdevConfig = {
        Name = "internal";
        Kind = "vlan";
      };
      vlanConfig.Id = 42;
    };
    networks.internal = {
      name = "internal";
      address = [ "10.0.16.1/22" ];
      networkConfig.IPForward = true;
      extraConfig = ''
        [Network]
        DHCPv6PrefixDelegation = yes
        IPv6SendRA = yes

        [IPv6SendRA]
        RouterLifetimeSec = 1800

        [DHCPv6PrefixDelegation]
        SubnetId = 2
        Token = ::1

        [CAKE]
        Bandwidth =
        '';
    };
    netdevs.uplink = {
      netdevConfig = {
        Name = "uplink";
        Kind = "vlan";
      };
      vlanConfig.Id = 1;
    };
    networks.uplink = {
      name = "uplink";
      DHCP = "yes";
      networkConfig = {
        IPForward = true;
        IPv6AcceptRA = true;
        IPv6PrivacyExtensions = true;
        #IPv6PrefixDelegation = "yes";
      };
      extraConfig = ''
        [CAKE]
        Bandwidth = 35M

        [DHCPv6]
        ForceDHCPv6PDOtherInformation = yes
      '';
    };
    networks.eth0 = {
      name = "eth0";
      vlan = [
        "internal"
        "uplink"
      ];
      extraConfig = ''
        [CAKE]
        Bandwidth =
      '';
    };
  };

  services.pdns-recursor = {
    enable = true;
    dns = {
      # Allow connections from everywhere and let the firewall do its buisness
      address = "0.0.0.0 ::";
      allowFrom = [ "0.0.0.0/0" "::/0" ];
    };
  };
  services.resolved.enable = false;
  networking.resolvconf.useLocalResolver = true;

  services.kea = {
    enable = true;
    interfaces = [ "internal" ];
    #interfaces = [ "*" ];
    additionalConfig = {
      Dhcp4 = {
        interfaces-config.dhcp-socket-type = "raw";
        subnet4 = [{
          subnet = "10.0.16.0/22";
          pools = [ { pool = "10.0.17.0-10.0.17.255"; } ];
          option-data = [
            { name = "routers"; data = "10.0.16.1"; }
            { name = "domain-name-servers"; data = "10.0.16.1"; }
          ];
        }];
      };
    };
  };

  users.users.nix = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCC4cFL1xcZOsIzXg1b/M4b89ofMKErNhg9s+0NdBVC beinke@th1"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPMkJA05G5ozn/pYRxrbQbk8lRynG4jH5LG1fua0Jo7c root@th1"
    ];
  };

  services.he-dns = {
    "roborock.beinqo.de" = {
      keyfile = "/etc/secrets/he_passphrase";
      takeIPv6FromInterface = "internal";
    };
  };

  nix.trustedUsers = [ "beinke" "nix" ];

  system.stateVersion = "19.03";

}
