{ mkMachine, flakes, ... }:

mkMachine
  {
    nixpkgs = flakes.nixpkgs-snm;
  }
  (
    {
      lib,
      pkgs,
      config,
      ...
    }:
    with lib;
    {

      system.stateVersion = "22.11";

      imports = [
        flakes.snm.nixosModule
      ];

      wat.installer.hcloud = {
        enable = true;
        macAddress = "96:00:00:33:c3:1e";
        ipv4Address = "78.47.82.136/32";
        ipv6Address = "2a01:4f8:c2c:e7b1::1/64";
      };

      wat.thelegy.acme = {
        enable = true;
        staging = false;
        extraDomainNames = [
          "autoconfig.0jb.de"
          "autoconfig.beinke.cloud"
          "imap.beinke.cloud"
          "smtp.beinke.cloud"
        ];
        dnsProvider = "hurricane";
      };
      wat.thelegy.backup = {
        enable = true;
        borgbaseRepo = "fdkpjo8i";
        extraReadWritePaths = [
          "/.backup-snapshots"
          "/var/vmail/.backup-snapshots"
        ];
      };
      wat.thelegy.base.enable = true;
      wat.thelegy.crowdsec.enable = true;
      wat.thelegy.nginx.enable = true;

      wat.thelegy.mailserver = {
        enable = true;
        autoconfigDomains = [
          "0jb.de"
          "beinke.cloud"
        ];
      };

      fileSystems."/var/vmail" = {
        device = "/dev/disk/by-label/vmail";
        fsType = "btrfs";
        options = [
          "noatime"
          "discard=async"
        ];
      };

      services = {
        acpid.enable = false;
        avahi.enable = false;
      };

      networking.nftables.firewall = {
        zones.tarpit = {
          ipv4Addresses = [
            "35.86.126.184"
          ];
        };
        rules.tarpit = {
          from = [ "tarpit" ];
          to = [ "fw" ];
          extraLines = [
            "counter drop"
          ];
        };
      };

      mailserver = {
        domains = [
          "0jb.de"
          "beinke.cloud"
          "die-cloud.org"
          "janbeinke.com"
        ];
        extraVirtualAliases = { };
        forwards = { };
        loginAccounts = {
          "jan@beinke.cloud" = {
            aliases = [
              "mail@0jb.de"
              "@janbeinke.com"
            ];
          };
          "uni@0jb.de" = {
            aliases = [
              "uni@janbeinke.com"
            ];
          };
          "admin@0jb.de" = { };
        };
      };

    }
  )
