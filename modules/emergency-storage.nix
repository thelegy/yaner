{ wat, ... }:
{
  flake.nixosModules.emergencyStorage = wat.mkModule [ "emergencyStorage" ] (
    {
      cfg,
      lib,
      pkgs,
      ...
    }:

    {

      namespaceOptions = {

        path = lib.mkOption {
          type = lib.types.str;
          default = "/emergencystorage";
        };

        size = lib.mkOption {
          type = lib.types.int;
          default = 1000;
        };

      };

      config = {

        systemd.services.emergencyStorage = {
          script = ''
            ${pkgs.coreutils}/bin/dd if=/dev/random bs=1M count=${toString cfg.size} of=${lib.escapeShellArg cfg.path}
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
