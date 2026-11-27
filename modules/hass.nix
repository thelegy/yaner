{ wat, ... }:
{
  flake.nixosModules.hass = wat.mkModule [ "hass" ] (
    {
      cfg,
      config,
      lib,
      pkgs,
      ...
    }:

    let

      ip = "192.168.1.30";
      domain = "ha.0jb.de";

      targetDir = "/var/lib/libvirt/hass";
      fileName = "hass.qcow2";

      machineUuid = "352e0f3b-494d-446c-98bf-8b3ee0728356";

      domainDescription = pkgs.writeText "hass.xml" ''
        <domain type="kvm">
          <name>hass</name>
          <uuid>${machineUuid}</uuid>
          <os>
            <type arch="x86_64">hvm</type>
            <loader readonly="yes" type="pflash">/run/libvirt/nix-ovmf/edk2-x86_64-code.fd</loader>
          </os>
          <features>
            <acpi/>
          </features>
          <vcpu>6</vcpu>
          <cpu mode="host-model" />
          <memory unit="G">6</memory>
          <currentMemory unit="G">4</currentMemory>
          <devices>
            <emulator>/run/libvirt/nix-emulators/qemu-kvm</emulator>
            <console type="pty" />
            <channel type="unix">
              <target type="virtio" name="org.qemu.guest_agent.0" />
            </channel>
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
            <interface type="bridge">
              <source bridge="iot" />
              <mac address="52:54:00:fb:c9:b6" />
              <model type="virtio" />
            </interface>
          </devices>
        </domain>
      '';

    in
    {

      wat.thelegy.libvirtd.enable = true;

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
            if ! state="$(${pkgs.libvirt}/bin/virsh domstate hass 2>&1)"; then
              domains="$(${pkgs.libvirt}/bin/virsh list --all --uuid)" || exit 1
              if ! ${pkgs.ripgrep}/bin/rg -Fxq '${machineUuid}' <<< "$domains"; then
                exit 0
              fi
              printf '%s\n' "$state" >&2
              exit 1
            fi
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

  );
}
