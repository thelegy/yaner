{ lib, config, pkgs, ... }:
with lib;

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
      "seal"
      "vers=3.0.2"
      "uid=${backupUser}"
    ];
  };

  services.borgbackup.repos = {
    agony = {
      path = "/mnt/backup-storage/agony";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHPhOxyZXi5Y44EJh3yHgQB5ZevQBA+YU1aaAM9at89d root@agony"
      ];
    };
    ender = {
      path = "/mnt/backup-storage/ender";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGZbGCnfx1ndfDHZ7w2QutSTgSbgSltqlDQGnQArYjwX root@ender"
      ];
      quota = "25G";
    };
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
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDrB+AEivcQUA8Eb9LbrNoXTdLqqnutKdow040ERcI2Z mc.dfhq.eu now with create mod"
      ];
      quota = "50G";
    };
    koma = {
      path = "/mnt/backup-storage/koma";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ+hk1SXcUMOVMv0UHuwSms81joCah51xg527es7hfuG root@brausefrosch"
      ];
       quota = "50G";
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
    y = {
      path = "/mnt/backup-storage/y";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILbZzyD6W2QQVyq9D36jkITPV8uA2Enf4gSwvWB49YEP root@y"
      ];
    };
  };

  systemd.services = mapAttrs' (repo: repoCfg: {
    name = "borgbackup-compact-${repo}";
    value = {
      path = with pkgs; [ borgbackup ];
      script = "borg compact --verbose ${repoCfg.path}";
      serviceConfig = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = repoCfg.path;
        User = backupUser;
      };
      startAt = "Mon 4:55";
    };
  }) config.services.borgbackup.repos;

}
