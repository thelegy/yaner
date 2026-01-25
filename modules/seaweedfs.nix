{
  lib,
  liftToNamespace,
  mkModule,
  pkgs,
  ...
}:
mkModule {

  options =
    cfg:
    liftToNamespace {

      master = {
        enable = lib.mkEnableOption "the seaweedfs master service";
      };

    };

  config =
    cfg:
    let
      package = pkgs.seaweedfs;
      weed = "${package}/bin/weed";
      hardenedService = {
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          DynamicUser = true;
          NoNewPrivileges = true;

          Type = "simple";
          Restart = "on-failure";

          # Filesystem / process isolation
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;

          # Kernel hardening
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectKernelLogs = true;
          ProtectControlGroups = true;
          ProtectProc = "invisible";
          ProcSubset = "pid";

          # Reduce ambient attack surface
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictSUIDSGID = true;
          RestrictRealtime = true;
          RestrictNamespaces = true;

          # Drop *all* Linux capabilities (SeaweedFS doesn’t need any in typical setups)
          CapabilityBoundingSet = "";
          AmbientCapabilities = "";

          # Networking families (Seaweed speaks TCP; allow IPv4/IPv6 + UNIX)
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_NETLINK"
          ];

          # Allow read/write only via StateDirectory/RuntimeDirectory/LogsDirectory.
          # (systemd automatically permits those paths even with ProtectSystem=strict)
          UMask = "0077";
        };
      };
      mkService = args: lib.recursiveUpdate hardenedService args;
    in
    {

      systemd.services.seaweedfs-master = lib.mkIf cfg.master.enable (mkService {
        serviceConfig = {
          ExecStart = "${weed} master";
        };
      });

    };
}
