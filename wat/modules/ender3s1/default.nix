{
  mkModule,
  liftToNamespace,
  config,
  lib,
  pkgs,
  ...
}:
with lib;

mkModule {

  options =
    cfg:
    liftToNamespace {

      mcu = mkOption {
        type = types.str;
        default = "stm32f401";
      };

      serial = mkOption {
        type = types.str;
        default = "/dev/ender3s1";
      };

      companionMcu = mkOption {
        type = types.str;
        default = "rp2040";
      };

      companionSerial = mkOption {
        type = types.nullOr types.str;
        default = null;
      };

      virtualSdcardPath = mkOption {
        type = types.str;
        default = "/srv/klipper";
      };

    };

  config = cfg: {

    # networking.firewall.allowedTCPPorts = [ 80 5900 ];
    #
    # systemd.network.networks."50-ve-ender3s1" = {
    #   matchConfig.Name = "ve-ender3s1";
    #   matchConfig.Kind = "veth";
    #   linkConfig = {
    #     RequiredForOnline = false;
    #   };
    #   networkConfig = {
    #     DHCPServer = true;
    #     IPMasquerade = "both";
    #     ConfigureWithoutCarrier = true;
    #   };
    #   address = [ "192.168.244.1/30" ];
    # };
    # systemd.nspawn.ender3s1 = {
    #   # filesConfig.Bind = [
    #   #   "/dev/serial/by-id/usb-Klipper_rp2040_45474150540338AA-if00"
    #   # ];
    #   # networkConfig.Bridge = "br0";
    # };
    #
    # systemd.targets.machines.wants = [ "systemd-nspawn@ender3s1.service" ];
    #
    # networking.nftables.firewall.zones.ender3s1 = {
    #   interfaces = [ "ve-ender3s1" ];
    # };
    # networking.nftables.firewall.rules.allow-dhcp = {
    #   from = [ "ender3s1" ];
    #   to = [ "fw" ];
    #   allowedUDPPorts = [ 67 ];
    # };
    # networking.nftables.firewall.rules.ender3s1-outbound = {
    #   from = [ "ender3s1" ];
    #   to = ["home"];
    #   verdict = "accept";
    # };
    #
    # networking.nat = {
    #   enable  = true;
    #   internalInterfaces = ["ve-ender3s1"];
    #   externalInterface = "br0";
    # };
    #
    # systemd.services.ser2net-ender3s1 = let
    #   conf = pkgs.writeText "ser2net.yaml" ''
    #     connection: &con01
    #       accepter: tcp,20201
    #       connector: serialdev,/dev/ender3s1,250000n81,local,dtr=off,rts=off
    #       options:
    #         kickolduser: true
    #   '';
    # in {
    #   serviceConfig = {
    #     DynamicUser = true;
    #     Type = "simple";
    #     ExecStart = "${pkgs.ser2net}/bin/ser2net -d -u -c ${conf}";
    #     SupplementaryGroups = [ "dialout" ];
    #   };
    # };
    # networking.nftables.firewall.rules.ender3s1 = {
    #   from = ["ender3s1"];
    #   to = ["fw"];
    #   allowedTCPPorts = [20201];
    # };

    services.nginx.virtualHosts."ender3s1.0jb.de" = {
      useACMEHost = config.networking.fqdn;
      forceSSL = true;
      locations."/" = {
        recommendedProxySettings = true;
        proxyWebsockets = true;
        # proxyPass = "http://192.168.244.2:7125";
        proxyPass = "http://ender3s1pi.0jb.de:7125";
        extraConfig = ''
          client_max_body_size 100M;
        '';
      };
    };

    services.nginx.virtualHosts.default2 = {
      locations."/ender3s1" = {
        recommendedProxySettings = true;
        proxyWebsockets = true;
        # proxyPass = "http://192.168.244.2:7125";
        proxyPass = "http://ender3s1pi.0jb.de:7125";
        extraConfig = ''
          client_max_body_size 100M;
        '';
      };
    };

    # KlipperScreen VNC
    services.nginx.appendConfig = ''
      stream {
        server {
          listen [fd7a:115c:a1e0::fd1a:221e]:5900;
          proxy_pass 192.168.244.2:5900;
        }
      }
    '';

  };

}
