{ mkMachine, flakes, ... }:

mkMachine {
  system = "aarch64-linux";
  nixpkgs = flakes.nixpkgs-roborock;
} ({ lib, config, pkgs, ... }:
with lib;

{

  imports = [
    ./hardware-configuration.nix
    ./usb.nix
  ];

  wat.thelegy.backup.enable = true;
  wat.thelegy.base.enable = true;
  wat.thelegy.builder.enable = true;
  wat.thelegy.firewall.enable = true;
  wat.thelegy.grocy.enable = true;


  # Use the extlinux boot loader. (NixOS wants to enable GRUB by default)
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

  services.chrony = {
    enable = true;
    servers = [];
    extraConfig = ''
      hwclockfile /etc/adjtime

      pool pool.ntp.org iburst xleave presend 512
      pool europe.pool.ntp.org iburst xleave presend 512

      server ntp1.lwlcom.net iburst xleave presend 512
      server ntp2.lwlcom.net iburst xleave presend 512
      server ntp3.lwlcom.net iburst xleave presend 512

      # Static kickstart ips (cloudflare anycast) to counteract missing rtc battery
      server 162.159.200.1 iburst xleave presend 512
      server 162.159.200.123 iburst xleave presend 512
    '';
  };

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
        RouterLifetimeSec = 300

        [DHCPv6PrefixDelegation]
        SubnetId = 2
        Token = ::1

        [CAKE]
        Bandwidth =
        '';
    };
    netdevs.internal2 = {
      netdevConfig = {
        Name = "internal2";
        Kind = "vlan";
      };
      vlanConfig.Id = 43;
    };
    networks.internal2 = {
      name = "internal2";
      networkConfig.IPForward = true;
      extraConfig = ''
        [Network]
        #DHCPv6PrefixDelegation = yes
        #IPv6SendRA = yes

        #[IPv6SendRA]
        #RouterLifetimeSec = 300

        #[DHCPv6PrefixDelegation]
        #Token = ::1

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
    networks.uplink2 = {
      name = "uplink2";
      DHCP = "ipv6";
      networkConfig = {
        IPForward = true;
        KeepConfiguration = "static";
      };
      extraConfig = ''
        [CAKE]
        Bandwidth = 35M

        [DHCPv6]
        ForceDHCPv6PDOtherInformation = yes
        WithoutRA = solicit
      '';
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
      '';
    };
    #networks.uplink = {
    #  name = "uplink";
    #  DHCP = "ipv4";
    #  networkConfig = {
    #    IPForward = true;
    #    #IPv6AcceptRA = true;
    #    #IPv6PrivacyExtensions = true;
    #    #IPv6PrefixDelegation = "yes";
    #  };
    #  extraConfig = ''
    #    [CAKE]
    #    Bandwidth = 35M
    #  '';
    #};
    netdevs.pppoe = {
      netdevConfig = {
        Name = "pppoe";
        Kind = "vlan";
      };
      vlanConfig.Id = 7;
    };
    networks.eth0 = {
      name = "eth0";
      vlan = [
        "internal"
        "uplink"
        "pppoe"
        "internal2"
      ];
      extraConfig = ''
        [CAKE]
        Bandwidth =
      '';
    };
  };

  networking.services = {
    mqtt = 1883;
    mqqts = 8883;
    pulseaudio-native = 4713;
    zigbee2mqtt-frontend = 8083;
    snapcast-stream = 1704;
    snapcast-control = 1705;
    snapcast-http = 1780;
  };

  networking.nftables.firewall = {
    zones = {
      internal = {
        interfaces = [ "internal" ];
      };
      external = {
        interfaces = [ "eth0" "ppp0" "uplink" "uplink2" ];
      };
      insecure = {
        parent = "external";
        ingressExpression = "ip saddr {192.168.1.0/24}";
        egressExpression = "ip daddr {192.168.1.0/24}";
      };
    };
    rules = {

      masquerade = {
        from = [ "internal" ];
        to = [ "external" ];
        masquerade = true;
      };

      outbound = {
        late = true;
        from = [ "internal" ];
        to = [ "external" "internal" ];
        verdict = "accept";
      };

      ext-to-fw = {
        from = [ "external" ];
        to = [ "fw" ];
        allowedServices = [
        ];
      };

      insecure-to-fw = {
        from = [ "insecure" ];
        to = [ "fw" ];
        allowedServices = [
          "http"
          "https"
          "snapcast-http"
          "snapcast-stream"
          "snapcast-control"
        ];
      };

      int-to-fw = {
        from = [ "internal" ];
        to = [ "fw" ];
        allowedServices = [
          "dns-udp"
          "dns-tcp"
          "dhcp-server"
          "mqtt"
          "http"
          "https"
          "pulseaudio-native"
          "zigbee2mqtt-frontend"
          "snapcast-stream"
          "snapcast-control"
        ];
      };

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

  services.pppd = {
    #enable = true;
    enable = false;
    peers.uplink2.config = ''
      ifname uplink2
      lock
      noauth
      +ipv6
      defaultroute
      defaultroute-metric 50
      defaultroute6
      plugin rp-pppoe.so
      nic-uplink
      file /etc/secrets/pppd.conf
    '';
  };

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

  #systemd.services.systemd-networkd.environment.SYSTEMD_LOG_LEVEL = "debug";

  users.users.beinke.extraGroups = [ "pulse-access" ];

  users.users.jens-nix = {
    isNormalUser = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILoGbf7pBykwDg0ODBT+1fb2ek3ojqnLG/tZeARAQhlt trusted-build-user@beini"
    ];
  };

  services.mosquitto = {
    enable = true;
    persistence = false;
    listeners = [{
      settings = {
        allow_anonymous = true;
      };
      acl = [ "topic readwrite #" ];
      users = {
        test = {
          hashedPassword = "$6$01MyUz3GvSvGfb3U$IQTl7uF0HNTbLAuZU8v7h0gkMS7R5HyCSqNJx7MpUyDeohnJOsrlh1KOC0MfhWBz2UyVR8J7kSUmS3ve+GxEvQ==";
          acl = [ "readwrite #" ];
        };
        nobody.acl = [ "readwrite #" ];
        tasmota = {
          acl = [ "readwrite tasmota/#" ];
          password = "tasmota";
        };
      };
    }];
  };

  services.he-dns = {
    "roborock.beinqo.de" = {
      keyfile = "/etc/secrets/he_passphrase";
      takeIPv6FromInterface = "internal";
    };
  };

  security.acme = {
    acceptTerms = true;
    #server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    defaults.email = "mail+letsencrypt@0jb.de";
    preliminarySelfsigned = false;
    certs = {
      "roborock.0jb.de" = {
        extraDomainNames = [
          "home.0jb.de"
          "grafana.0jb.de"
          "grocy.0jb.de"
        ];
        dnsProvider = "hurricane";
        credentialsFile = "/etc/secrets/acme";
        group = "nginx";
        postRun = ''
          systemctl start --failed nginx.service
          systemctl reload nginx.service
        '';
      };
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
    daemon.config.default-sample-rate = 48000;
    tcp = {
      enable = true;
      anonymousClients.allowAll = true;
      #anonymousClients.allowedIpRanges = [ "127.0.0.1" "192.168.1.1/24" "10.0.16.1/20" ];
    };
    extraConfig = ''
      load-module module-pipe-sink file=/run/pulse/snapfifo sink_name=snapcast sink_properties=device.description=Snapcast format=s16le rate=48000
      load-module module-null-sink sink_name=main channels=2 sink_properties=device.description=Main
      load-module module-loopback source=main.monitor sink=alsa_output.usb-Focusrite_Saffire_6USB2.0-00.analog-surround-40

      #load-module module-combine-sink sink_name=main channels=2 slaves=alsa_output.usb-Focusrite_Saffire_6USB2.0-00.analog-surround-40,alsa_output.usb-JABRA_GN_2000_MS_USB-00.analog-stereo sink_properties=device.description=Main
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

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts.main = {
      serverName = "roborock.0jb.de";
      forceSSL = true;
      useACMEHost = "roborock.0jb.de";
    };
    virtualHosts."home.0jb.de" = {
      forceSSL = true;
      useACMEHost = "roborock.0jb.de";
      locations."/snapcast/" = {
        alias = "${pkgs.snapcast}/share/snapserver/snapweb/";
        extraConfig = ''
          sub_filter 'window.location.host' 'window.location.host + "/snapcast"';
          sub_filter_types application/javascript;
          sub_filter_once on;
        '';
      };
      locations."/snapcast/jsonrpc" = {
        proxyPass = "http://localhost:1780/jsonrpc";
        proxyWebsockets = true;
      };
      locations."/snapcast/stream" = {
        proxyPass = "http://localhost:1780/stream";
        proxyWebsockets = true;
      };
    };
  };

  services.spotifyd = {
    enable = true;
    config = ''
      [global]
      username_cmd = "cat $CREDENTIALS_DIRECTORY/user"
      password_cmd = "cat $CREDENTIALS_DIRECTORY/password"
      backend = "pulseaudio"
      device_name = "${config.networking.hostName}"
      device_type = "speaker"
    '';
  };
  systemd.services.spotifyd = {
    serviceConfig = {
      SupplementaryGroups = [ "pulse-access" ];
      LoadCredential = [
        "user:/etc/secrets/spotify_user"
        "password:/etc/secrets/spotify_password"
      ];
    };
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
      Restart = "always";
    };
    wantedBy = [ "multi-user.target" ];
  };

  programs.sway.enable = true;

  services.greetd = {
    enable = true;
    restart = false;
    #settings.default_session = {
    #  command = "sway";
    #  user = "beinke";
    #};
    settings.default_session = {
      command = pkgs.writeScript "tmux-session" ''
        ${pkgs.tmux}/bin/tmux new -d -s greeter '${pkgs.htop}/bin/htop; zsh' 2>/dev/null
        ${pkgs.tmux}/bin/tmux attach -r -t greeter
      '';
      user = "root";
    };
  };

  environment.systemPackages = with pkgs; [
    tcpdump
    config.services.kea.package
    pdns-recursor
  ];

  nix.settings.trusted-users = [ "beinke" "jens-nix" ];

  system.stateVersion = "19.03";

})
