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
