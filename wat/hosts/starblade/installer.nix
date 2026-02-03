{
  lib,
  wat-installer-lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  disk1 = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NU0XB24810M";
  disk2 = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_1TB_S6Z1NU0X827864W";
  systemSize = "100GiB";
  zilSize = "32GiB";
  inherit (wat-installer-lib) uuidgen;
  hostname = config.networking.hostName;
  luksUuid = uuidgen { name = "system-luks"; };
  efiPartUuid1 = uuidgen { name = "efi-part1"; };
  efiPartUuid2 = uuidgen { name = "efi-part2"; };
  systemPartUuid1 = uuidgen { name = "system-part1"; };
  systemPartUuid2 = uuidgen { name = "system-part2"; };
  systemUuid = uuidgen { name = "system"; };
  systemLabel = "sys${hostname}";
in
{

  boot.initrd.availableKernelModules = [
    "xfs"
  ];

  boot.loader.systemd-boot.enable = mkDefault true;
  boot.loader.systemd-boot.configurationLimit = 15;

  boot.swraid = {
    enable = true;
  };

  services.fstrim.enable = true;

  boot.initrd.luks.devices.${hostname} = {
    device = "/dev/disk/by-uuid/${luksUuid}";
    allowDiscards = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/${systemUuid}";
    fsType = "xfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-partuuid/${efiPartUuid1}";
    fsType = "vfat";
    options = [
      "uid=0"
      "gid=0"
      "fmask=0077"
      "dmask=0077"
    ];
  };

  wat.build.installer.launcher.fragments = {
    formatConfig = {
      before = [ "format" ];
      content = localPkgs: ''
        echo Please enter the luks passphrase... >&2
        read -rs luksPassphrase

        echo Please reenter the luks passphrase to confirm... >&2
        read -rs luksPassphraseConfirm

        if [[ $luksPassphrase != $luksPassphraseConfirm ]]; then
          echo Passphrases did not match >&2
          exit 1
        fi

        formatConfig="
          {
            \"luksPassphrase\": $(${localPkgs.jq}/bin/jq -R <<<$luksPassphrase)
          }
        "
      '';
    };
  };

  wat.build.installer.format.fragments = {

    configure = {
      content = ''
        installDisk1=${escapeShellArg disk1}
        installDisk2=${escapeShellArg disk2}
        efiPartUuid1=${escapeShellArg efiPartUuid1}
        efiPartUuid2=${escapeShellArg efiPartUuid2}
        systemPartUuid1=${escapeShellArg systemPartUuid1}
        systemPartUuid2=${escapeShellArg systemPartUuid2}
        systemSize=${escapeShellArg systemSize}
        zilSize=${escapeShellArg zilSize}
        systemUuid=${escapeShellArg systemUuid}
        systemLabel=${escapeShellArg systemLabel}
        hostname=${escapeShellArg hostname}
      '';
    };

    luksConfigure = {
      after = [ "configure" ];
      before = [ "wipe" ];
      content = ''
        luksUuid=${escapeShellArg luksUuid}
        preData=$(</dev/stdin)
        luksPassphrase=$(${pkgs.jq}/bin/jq -r '.luksPassphrase' <<<$preData)
        unset preData

        luksVolName=cryptvol_$hostname
        systemPartition=/dev/mapper/$luksVolName
      '';
    };

    wipe = {
      after = [ "configure" ];
      content = ''
        echo Wiping partition table
        ${pkgs.coreutils}/bin/dd if=/dev/zero of=$installDisk1 bs=1M count=1 conv=fsync
        ${pkgs.coreutils}/bin/dd if=/dev/zero of=$installDisk2 bs=1M count=1 conv=fsync

        echo Ensure partition table changes are known to the kernel
        ${pkgs.busybox}/bin/partprobe $installDisk1
        ${pkgs.busybox}/bin/partprobe $installDisk2

        echo Discard disk contents
        ${pkgs.util-linux}/bin/blkdiscard $installDisk1
        ${pkgs.util-linux}/bin/blkdiscard $installDisk2
      '';
    };

    partitionOuter = {
      after = [ "wipe" ];
      content = ''
        echo Creating partition tables
        ${pkgs.util-linux}/bin/sfdisk $installDisk1 <<EOF
          label: gpt
          1 : start=2048, size=512MiB, type=uefi, name="esp1", uuid="$efiPartUuid1"
          2 : size=$systemSize, type=linux-raid, name="system1", uuid="$systemPartUuid1"
          3 : size=$zilSize, type=solaris-root, name="zil1"
          4 : type=solaris-root, name="l2arc1", name="l2arc1"
        EOF
        ${pkgs.util-linux}/bin/sfdisk $installDisk2 <<EOF
          label: gpt
          1 : start=2048, size=512MiB, type=uefi, name="esp2", uuid="$efiPartUuid2"
          2 : size=$systemSize, type=linux-raid, name="system2", uuid="$systemPartUuid2"
          3 : size=$zilSize, type=solaris-root, name="zil2"
          4 : type=solaris-root, name="l2arc1", name="l2arc2"
        EOF

        echo Ensure partition table changes are known to the kernel
        ${pkgs.busybox}/bin/partprobe $installDisk1
        ${pkgs.busybox}/bin/partprobe $installDisk2
        ${pkgs.systemdMinimal}/bin/udevadm settle
      '';
    };

    prepareRaid = {
      after = [ "partitionOuter" ];
      content = ''
        echo Assemble System raid1
        ${pkgs.mdadm}/bin/mdadm --create --verbose --level=1 --metadata=1.2 --raid-devices=2 /dev/md/system /dev/disk/by-partuuid/$systemPartUuid1 /dev/disk/by-partuuid/$systemPartUuid2
      '';
    };

    formatEfi = {
      after = [ "prepareRaid" ];
      content = ''
        echo Create EFI partition
        ${pkgs.dosfstools}/bin/mkfs.fat -F32 -n ESP /dev/disk/by-partuuid/$efiPartUuid1
      '';
    };

    luksSetup = {
      after = [ "partitionOuter" ];
      before = [ "setupInner" ];
      content = ''
        echo Create LUKS cryptvol
        : ''${luksPartition:=/dev/md/system}
        ${pkgs.cryptsetup}/bin/cryptsetup --batch-mode --key-file <(echo -n $luksPassphrase) luksFormat --type luks2 --uuid $luksUuid $luksPartition

        echo Mounting LUKS cryptvol for the first time
        luksSsdOptions=()
        luksSsdOptions=(--allow-discards --persistent)
        ${pkgs.cryptsetup}/bin/cryptsetup --batch-mode --key-file <(echo -n $luksPassphrase) $luksSsdOptions open $luksPartition $luksVolName
        unset luksPassphrase
      '';
    };

    setupInner = {
      after = [ "formatEfi" ];
      content = ''
        echo Format system partition
        ${pkgs.xfsprogs}/bin/mkfs.xfs -L $systemLabel -m uuid=$systemUuid $systemPartition

        echo Mount the system
        ${pkgs.util-linux}/bin/mount $systemPartition /mnt
        ${pkgs.coreutils}/bin/mkdir -p /mnt/boot
        ${pkgs.util-linux}/bin/mount -o uid=0,gid=0,fmask=0077,dmask=0077 /dev/disk/by-partuuid/$efiPartUuid1 /mnt/boot
      '';
    };

  };

}
