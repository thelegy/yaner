{ mkModule
, liftToNamespace
, lib
, config
, pkgs
, ...
}:
with lib;

# Initial setup (login):
# > sudo -u tailscale tailscale up --netfilter-mode=off

mkModule {
  options = cfg: liftToNamespace {

    port = mkOption {
      type = types.port;
      default = 41641;
      description = lib.mdDoc "The port to listen on for tunnel traffic (0=autoselect).";
    };

    interfaceName = mkOption {
      type = types.str;
      default = "tailscale";
      description = lib.mdDoc ''The interface name for tunnel traffic. Use "userspace-networking" (beta) to not use TUN.'';
    };

  };
  config = cfg: {

    networking.firewall.allowedUDPPorts = [ cfg.port ];

    networking.networkmanager.unmanaged = [ cfg.interfaceName ];
    networking.dhcpcd.denyInterfaces = [ cfg.interfaceName ];

    systemd.services.tailscaled = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-pre.target" ];
      after = [ "network-pre.target" "NetworkManager.service" "systemd-resolved.service" ];
      serviceConfig = rec {
        AmbientCapabilities = [
          "CAP_NET_ADMIN"
        ];
        CapabilityBoundingSet = mkForce AmbientCapabilities;

        ExecStartPre = "+${pkgs.kmod}/bin/modprobe tun";
        ExecStart = "${pkgs.tailscale}/bin/tailscaled --port ${toString cfg.port} --tun ${lib.escapeShellArg cfg.interfaceName} --no-logs-no-support";

        User = "tailscale";
        Group = "tailscale";
        ProtectHome = true;
        ProtectProc = "invisible";
        ProtectKernelTunables = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;

        PrivateTmp = true;
        RemoveIPC = true;
        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        ProtectSystem = "strict";

        DeviceAllow = "/dev/net/tun";

        RuntimeDirectory = "tailscale";
        RuntimeDirectoryMode = "0755";
        StateDirectory = "tailscale";
        StateDirectoryMode = "0700";
        CacheDirectory = "tailscale";
        CacheDirectoryMode = "0750";
        Type = "notify";
      };
    };

    environment.systemPackages = [
      pkgs.tailscale
    ];

    users.users.tailscale = {
      isSystemUser = true;
      group = "tailscale";
    };
    users.groups.tailscale = { };

    networking.nftables.firewall = {
      zones.tailscale-range = {
        ipv6Addresses = [ "fd7a:115c:a1e0:ab12::/64" ];
      };
      zones.tailscale = {
        parent = "tailscale-range";
        interfaces = [ cfg.interfaceName ];
      };
      rules.tailscale-spoofing = {
        from = [ "tailscale-range" ];
        to = "all";
        extraLines = [
          "iifname \"${cfg.interfaceName}\" return"
          "counter drop"
        ];
      };
    };

  };
}
