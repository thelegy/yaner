{ wat, ... }:
{
  flake.nixosModules.emergencyStorage = wat.mkModuleWrapped [ "emergencyStorage" ] (
    {
      cfg,
      lib,
      pkgs,
      ...
    }:
    with lib;

    {

      options = {

        path = mkOption {
          type = types.str;
          default = "/emergencystorage";
        };

        size = mkOption {
          type = types.int;
          default = 1000;
        };

      };

      config = {

        systemd.services.emergencyStorage = {
          script = ''
            ${pkgs.coreutils}/bin/dd if=/dev/random bs=1M count=${toString cfg.size} of=${escapeShellArg cfg.path}
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = false;
          };
          unitConfig.ConditionPathExists = "!${cfg.path}";
          startAt = [ "daily" ];
          wantedBy = [ "multi-user.target" ];
        };

        wat.thelegy.backup.extraExcludes = [
          cfg.path
        ];

      };

    }

  );
}
