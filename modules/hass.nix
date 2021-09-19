{ mkTrivialModule

, config
, lib
, pkgs

, ... }: with lib;

let

  targetDir = "/var/lib/libvirt/hass";
  fileName = "hass.qcow2";
  imageUrl = "https://github.com/home-assistant/operating-system/releases/download/6.3/haos_ova-6.3.qcow2.xz";

  machineUuid = "352e0f3b-494d-446c-98bf-8b3ee0728356";

  domainDescription = pkgs.writeText "hass.xml" ''
    <domain type="kvm">
      <name>hass</name>
      <uuid>${machineUuid}</uuid>
      <os>
        <type arch="x86_64">hvm</type>
        <loader readonly="yes" type="pflash">/run/libvirt/nix-ovmf/OVMF_CODE.fd</loader>
      </os>
      <features>
        <acpi/>
      </features>
      <vcpu>2</vcpu>
      <cpu mode="host-model" />
      <memory unit="G">4</memory>
      <currentMemory unit="G">1</currentMemory>
      <devices>
        <emulator>/run/libvirt/nix-emulators/qemu-kvm</emulator>
        <console type="pty" />
        <disk type="file" device="disk">
          <driver name="qemu" type="qcow2" />
          <source file="${targetDir}/${fileName}" />
          <target dev="sda" bus="virtio" />
        </disk>
        <interface type="bridge">
          <source bridge="br0" />
          <mac address="52:54:00:8b:02:8b" />
          <model type="virtio" />
        </interface>
        <hostdev mode="subsystem" type="usb">
          <source startupPolicy="optional">
            <vendor id="0x0451" />
            <product id="0x16a8" />
          </source>
        </hostdev>
      </devices>
    </domain>
  '';

in mkTrivialModule {

  virtualisation.libvirtd = {
    enable = true;
    qemuPackage = mkDefault pkgs.qemu_kvm;
    qemuRunAsRoot = false;
    onShutdown = "shutdown";
  };

  systemd.services.hass-image = {
    serviceConfig.Type = "oneshot";
    unitConfig.ConditionPathExists = "!${targetDir}/${fileName}";
    script = ''
      ${pkgs.coreutils}/bin/mkdir -p "${targetDir}"
      ${pkgs.curl}/bin/curl --fail --no-progress-meter --location --output "${targetDir}/${fileName}.xz" "${imageUrl}"
      ${pkgs.xz}/bin/xz --decompress "${targetDir}/${fileName}.xz"
    '';
  };

  systemd.services.hass-vm = {
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
      TimeoutStopSec = "3m";
    };
    after = [
      "libvirtd.service"
    ];
    wants = [
    ];
    requires = [
      "libvirtd.service"
    ];
    script = ''
      ${pkgs.libvirt}/bin/virsh 'create ${domainDescription} --autodestroy; event --domain hass --event lifecycle'
    '';
    preStop = ''
      while true; do
        state="$(${pkgs.libvirt}/bin/virsh domstate hass)"
        case "$state" in
          running)
            ${pkgs.libvirt}/bin/virsh shutdown hass
            ;;
          paused)
            ${pkgs.libvirt}/bin/virsh resume hass
            ;;
          pmsuspended)
            ${pkgs.libvirt}/bin/virsh dompmwakeup hass
            ;;
          "in shutdown")
            ;;
          *)
            break
            ;;
        esac
        sleep 5
      done
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
