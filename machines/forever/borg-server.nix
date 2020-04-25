{ pkgs, ... }:

let

  automountOptions = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
  backupDir = "/mnt/backup-storage";
  backupUser = "borg";

in {

  users.users."${backupUser}" = { };

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
    th1 = {
      path = "/mnt/backup-storage/th1";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPMkJA05G5ozn/pYRxrbQbk8lRynG4jH5LG1fua0Jo7c root@th1"
      ];
    };
    mail = {
      path = "/mnt/backup-storage/mailserver";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICC+tSHBpxjuQWw4awATyFUAB8TTYHYi/54vh/ijXP+R root@mail"
      ];
    };
    koma-valhalla = {
      path = "/mnt/backup-storage/koma-valhalla";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIc+1VOzezO7njdd9Ma6o3+SYUzpvfWjnAI4v10MuzIN ansible-generated on valhalla"
      ];
      quota = "25G";
    };
    itkeller-mc = {
      path = "/mnt/backup-storage/itkeller-mc";
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM+VRZSAJ+6Zv71G40gAiqbjl0qMBwAFBbuZePZIbbnP minecraft@minecraft"
      ];
      quota = "5G";
    };
  };

}
