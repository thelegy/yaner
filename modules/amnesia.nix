{ mkTrivialModule
, ... }:

mkTrivialModule {

  fileSystems.amnesia = {
    mountPoint = "/mnt/amnesia";
    device = "//amnesia.subraum.c3pb.de/datengrab";
    fsType = "cifs";
    options = [
      "uid=1000"
      "guest"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.device-timeout=5s"
      "x-systemd.mount-timeout=5s"
      "vers=1.0"
    ];
  };

}
