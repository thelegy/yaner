{ mkMachine, ... }:

mkMachine { } (
  {
    lib,
    config,
    pkgs,
    ...
  }:
  with lib;

  {
    imports = [
      ./hardware-configuration.nix
    ];

    wat.thelegy.base.enable = true;

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.vlans.internal = {
      id = 63;
      interface = "enp1s0";
    };

    networking.interfaces.internal = {
      ipv4.addresses = [
        {
          address = "192.168.42.1";
          prefixLength = 24;
        }
      ];
    };

    networking.dhcpcd.extraConfig = ''
      duid
      noipv6rs
      waitip 6
      # Uncomment this line if you are running dhcpcd for IPv6 only.
      #ipv6only

      # use the interface connected to WAN
      interface enp1s0
      ipv6rs
      iaid 1
      # use the interface connected to your LAN
      #ia_pd 1 internal
      ia_pd 1/::/64 internal/0/64
    '';

    networking.nat = {
      enable = true;
      externalInterface = "enp1s0";
      internalInterfaces = [ "internal" ];
    };

    boot.kernel.sysctl = {
      "net.ipv6.conf.all.forwarding" = true;
    };

    services.kea = {
      enable = true;
      interfaces = [ "internal" ];
    };

    services.radvd = {
      enable = true;
      config = ''
        interface internal {
          AdvSendAdvert on;
          MinRtrAdvInterval 3;
          MaxRtrAdvInterval 10;
          prefix ::/64 {
            AdvRouterAddr on;
            AdvPreferredLifetime 30;
            AdvValidLifetime 60;
          };
        };
      '';
    };

    services.printing = {
      enable = true;
      browsing = true;
      defaultShared = true;
      extraConf = ''
        DefaultLanguage de_DE
        DefaultPaperSize A4
      '';
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
    };
    hardware.printers.ensureDefaultPrinter = "olhado";
    hardware.printers.ensurePrinters = [
      {
        name = "olhado";
        model = "drv:///sample.drv/generic.ppd";
        deviceUri = "socket://10.0.0.111:9100";
        ppdOptions = {
          PageSize = "A4";
          Option1 = "True"; # Enable the Duplexer
        };
      }
    ];

    services.avahi = {
      enable = true;
      publish.enable = true;
      publish.userServices = true;
      nssmdns4 = true;
    };

    networking = {
      firewall = {
        allowedTCPPorts = [ 631 ];
        allowedUDPPorts = [ 631 ];
      };
    };

    # services.dhcpd4 = {
    #   enable = true;
    #   interfaces = [ "internal" ];
    #   extraConfig = ''
    #     subnet 192.168.42.0 netmask 255.255.255.0 {
    #      range 192.168.42.100 192.168.42.200;
    #     }
    #   '';
    # };

    services.he-dns = {
      "home.beinqo.de" = {
        keyfile = "/etc/secrets/he_passphrase";
      };
    };

    system.stateVersion = "19.09"; # Did you read the comment?

  }
)
