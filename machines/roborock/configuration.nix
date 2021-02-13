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

  sound.enable = true;
  hardware.pulseaudio = {
    enable = true;
    systemWide = true;
    configFile = let
      cfg = config.hardware.pulseaudio;
      hasZeroconf = let z = cfg.zeroconf; in z.publish.enable || z.discovery.enable;
      overriddenPackage = cfg.package.override
      (optionalAttrs hasZeroconf { zeroconfSupport = true; });
      originalConfigFile = "${getBin overriddenPackage}/etc/pulse/default.pa";
    in pkgs.runCommand "default.pa" {} ''
      sed -r 's|(load-module module-native-protocol-unix)|\1 auth-anonymous=1|' ${originalConfigFile} > $out
    '';
    extraConfig = ''
      load-module module-pipe-sink file=/run/pulse/snapfifo sink_name=Snapcast sink_properties=device.description=Snapcast format=s16le rate=48000
    '';
  };
  users.groups.pulse-access = {};
  users.users.pulse.createHome = mkForce false;
  systemd.tmpfiles.rules = [
    "d /run/pulse 0755 pulse pulse -"
  ];

  services.snapserver = {
    enable = true;
    port = config.networking.services.snapcast-stream.port;
    streams.pulse = {
      type = "pipe";
      location = "/run/pulse/snapfifo";
      query = {
        mode = "read";
      };
    };
    tcp = {
      enable = true;
      port = config.networking.services.snapcast-control.port;
    };
  };

  services.spotifyd = {
    enable = true;
    config = ''
      [global]
      username_cmd = "head -n1 /etc/secrets/spotify"
      password_cmd = "tail -n1 /etc/secrets/spotify"
      backend = "pulseaudio"
      device_name = "${config.networking.hostName}"
      device_type = "speaker"
    '';
  };
  users.groups.spotify = {};
  systemd.services.spotifyd = {
    serviceConfig.SupplementaryGroups = [ "spotify" "pulse-access" ];
    environment = {
      SHELL = "/bin/sh";
      #PULSE_LOG = "4";
    };
  };

  systemd.services.wdr2 = {
    serviceConfig = {
      DynamicUser = true;
      ExecStart = "${pkgs.mpv}/bin/mpv --script=${pkgs.mpv_autospeed} -af scaletempo --ao=pulse --no-terminal https://www1.wdr.de/radio/player/radioplayer104~_layout-popupVersion.html";
      SupplementaryGroups = [ "pulse-access" ];
    };
    wantedBy = [ "multi-user.target" ];
  };

  services.qd = {
    enable = true;
    mqttUri = "mqtt://localhost";
  };

  environment.systemPackages = with pkgs; [
    tcpdump
    config.services.kea.package
    pdns-recursor
  ];

  nix.trustedUsers = [ "beinke" "nix" ];

  system.stateVersion = "19.03";

}
