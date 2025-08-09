{
  config,
  lib,
  mkTrivialModule,
  pkgs,
  ...
}:
with lib;
let
  dir = "/srv/libation";
  group = config.services.audiobookshelf.group;
  sshKeys = config.users.users.root.openssh.authorizedKeys.keys;
  user = "libation";
in
mkTrivialModule {
  systemd.tmpfiles.rules = [ "d ${dir} 0750 ${user} ${group}" ];
  wat.thelegy.backup.extraExcludes = [ dir ];
  users.groups.libation = { };
  users.users.${user} = {
    isSystemUser = true;
    useDefaultShell = true;
    createHome = true;
    home = "/home/libation";
    group = "libation";
    openssh.authorizedKeys.keys = sshKeys;
    packages = [
      pkgs.libation
    ];
  };
  systemd.services.libation = {
    serviceConfig = {
      Type = "oneshot";
      User = user;
      ExecStart = [
        "${pkgs.libation}/bin/libationcli scan"
        "${pkgs.libation}/bin/libationcli liberate"
      ];
    };
    startAt = "*:0/15";
  };
}
