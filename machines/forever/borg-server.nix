{ pkgs, ... }:

let

  automountOptions = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
  backupDir = "/mnt/backup-storage";
  backupUser = "borg";

in {

  users.users."${backupUser}" = { };

  systemd.tmpfiles.rules = [ "d ${backupDir} 0755 root root - -" ];
  fileSystems."${backupDir}" = {
    device = "//u189274-sub1.your-storagebox.de/u189274-sub1";
    fsType = "cifs";
    options = [
      automountOptions
      "credentials=/etc/secrets/backup-cifs-credentials"
      "uid=${backupUser}"
    ];
  };

  services.borgbackup.repos = {
    ever = {
      path = "/mnt/backup-storage/ever";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3r0YJIUoGGIzmCrF/uiF5rEzD/B1nszoNhHehVLjXw root@ever"
      ];
    };
    forever = {
      path = "/mnt/backup-storage/forever";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGl9EWHsYRe7cvISO1wlFdQ2I7jxqlEZ9NNjzykKdsTg root@forever"
      ];
    };
    itkeller-mc = {
      path = "/mnt/backup-storage/itkeller-mc";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+VRZSAJ+6Zv71G40gAiqbjl0qMBwAFBbuZePZIbbnP minecraft@minecraft"
      ];
      quota = "25G";
    };
    koma-valhalla = {
      path = "/mnt/backup-storage/koma-valhalla";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIc+1VOzezO7njdd9Ma6o3+SYUzpvfWjnAI4v10MuzIN ansible-generated on valhalla"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOql+/Ly/ey2XGg5hzZnrBg3xqpWIQz7t9FSbdWz3lus root@honigkuchenpferd"
      ];
      quota = "25G";
    };
    mail = {
      path = "/mnt/backup-storage/mailserver";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICC+tSHBpxjuQWw4awATyFUAB8TTYHYi/54vh/ijXP+R root@mail"
      ];
    };
    roborock = {
      path = "/mnt/backup-storage/roborock";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFFAkNZbkfRNHy8sbL44yCxqmVpe0NjH3P/dl+XH9icH root@roborock"
      ];
    };
    th1 = {
      path = "/mnt/backup-storage/th1";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPMkJA05G5ozn/pYRxrbQbk8lRynG4jH5LG1fua0Jo7c root@th1"
      ];
    };
  };

}
