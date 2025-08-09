{
  mkModule,
  liftToNamespace,
  lib,
  pkgs,
  ...
}:
with lib;

mkModule {

  options = liftToNamespace {

    path = mkOption {
      type = types.str;
      default = "/emergencystorage";
    };

    size = mkOption {
      type = types.int;
      default = 1000;
    };

  };

  config = cfg: {

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
