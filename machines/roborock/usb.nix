{ lib, config, pkgs, ...}:
with lib;

{

  boot.kernelPatches = [
    {
      # Got the idea from https://www.diyaudio.com/forums/pc-based/341590-using-raspberry-pi-4-usb-dsp-dac-5.html#post5893255
      name = "fix-uac2-for-win10";
      patch = ./linux-fix-uac2-for-windows.patch;
    }
  ];

  boot.kernelPackages = let
    crossPackages = import "${config.nix.registry.nixpkgs.flake}/pkgs/top-level/default.nix" {
      localSystem = "x86_64-linux";
      crossSystem = config.nixpkgs.localSystem;
    };
    #crossPackages = pkgs.forceSystem "x86_64-linux" "";
    #crossPackages = flakes.nixpkgs.legacyPackages.x86_64-linux.pkgsCross.aarch64-multiplatform;
  in crossPackages.linuxPackages_latest;


  hardware.deviceTree.overlays = let
    kernelIncludesDir = "${config.hardware.deviceTree.kernelPackage.dev}/lib/modules/${config.hardware.deviceTree.kernelPackage.version}/source/include";
    preprocessDts = text: pkgs.runCommandCC "overlay.dts" {inherit text;} ''
      cpp -nostdinc -I ${kernelIncludesDir} -undef -x assembler-with-cpp - > $out <<<"$text"
    '';
    rockpro64-fix-typec = {
      name = "rockpro64-fix-typec";
      dtsFile = preprocessDts ''
        /dts-v1/;
        /plugin/;
        #include <dt-bindings/usb/pd.h>
        / {
          compatible = "pine64,rockpro64";
        };
        &fusb0 {
          //port {
          //  fusb0_role_sw: endpoint {
          //    remote-endpoint = <&usbdrd_dwc3_0_role_sw>;
          //  };
          //};
          usb_con0: connector {
            compatible = "usb-c-connector";
            label = "USB-C";
            power-role = "source";
            source-pdos = <PDO_FIXED(5000, 2000, PDO_FIXED_DUAL_ROLE | PDO_FIXED_DATA_SWAP | PDO_FIXED_USB_COMM)>;
            data-role = "dual";
            //self-powered; // only relevant if power-role not source
            //typec-power-opmode = "default";
            ports {
              #address-cells = <1>;
              #size-cells = <0>;
              port@0 {
                reg = <0>;
                typec0_hs: endpoint {
                  remote-endpoint = <&u2phy0_typec_hs>;
                };
              };
              port@1 {
                reg = <1>;
                typec0_ss: endpoint {
                  remote-endpoint = <&tcphy0_typec_ss>;
                };
              };
              port@2 {
                reg = <2>;
                typec0_dp: endpoint {
                  remote-endpoint = <&tcphy0_typec_dp>;
                };
              };
            };
          };
        };
        &u2phy0_otg {
          //extcon = <&fusb0>;
          extcon = <&usb_con0>;
          port {
            u2phy0_typec_hs: endpoint {
              remote-endpoint = <&typec0_hs>;
            };
          };
        };
        &tcphy0 {
          //extcon = <&fusb0>;
          extcon = <&usb_con0>;
        };
        &tcphy0_usb3 {
          port {
            tcphy0_typec_ss: endpoint {
              remote-endpoint = <&typec0_ss>;
            };
          };
        };
        &tcphy0_dp {
          port {
            tcphy0_typec_dp: endpoint {
              remote-endpoint = <&typec0_dp>;
            };
          };
        };
        //&usbdrd_dwc3_0 {
        //  dr_mode = "otg";
        //  usb-role-switch;
        //  role-switch-default-mode = "host";
        //};
        &usbdrd_dwc3_0 {
          dr_mode = "peripheral";
          //extcon = <&fusb0>;
          //port {
          //  usbdrd_dwc3_0_role_sw: endpoint {
          //    remote-endpoint = <&fusb0_role_sw>;
          //  };
          //};
        };
      '';
    };
    rockpro64-fix-typec2 = {
      name = "rockpro64-fix-typec";
      dtsFile = preprocessDts ''
        /dts-v1/;
        /plugin/;
        #include <dt-bindings/usb/pd.h>
        / {
          compatible = "pine64,rockpro64";
        };
        &usbdrd_dwc3_0 {
          dr_mode = "peripheral";
        };
      '';
    };
  in [ rockpro64-fix-typec2 ];


  systemd.services.usb-gadgegt-config = let
    gadget = "/sys/kernel/config/usb_gadget/hid";
    udc = "fe800000.usb";
    writeReportDescriptor = descriptorString: pkgs.runCommandNoCC "HidReportDescriptor" {inherit descriptorString;} ''
      cat <<<$descriptorString | sed 's/#.*//g' | tr -cd '0-9a-fA-F' | sed -r 's/../\\\\x\0/g' | xargs -- echo -ne > $out
    '';
  in {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = pkgs.writeShellScript "configure-usb-gadget" ''
        set -e

        /run/current-system/sw/bin/modprobe libcomposite

        mkdir -p ${gadget}
        echo 0x1d6b > ${gadget}/idVendor
        echo 0x0104 > ${gadget}/idProduct
        echo 0x0100 > ${gadget}/bcdDevice
        echo 0x0200 > ${gadget}/bcdUSB
        echo 0x08 > ${gadget}/bMaxPacketSize0

        mkdir -p ${gadget}/strings/0x409
        echo 42 > ${gadget}/strings/0x409/serialnumber
        echo the legy > ${gadget}/strings/0x409/manufacturer
        echo dummy keyboard > ${gadget}/strings/0x409/product

        mkdir -p ${gadget}/configs/c.1

        # Setup Keyboard
        mkdir -p ${gadget}/functions/hid.usb0
        echo 1 > ${gadget}/functions/hid.usb0/protocol
        echo 1 > ${gadget}/functions/hid.usb0/subclass
        # hid boot keyboard descriptor
        cat >${gadget}/functions/hid.usb0/report_desc <${writeReportDescriptor ''
          05 01  # USAGE_PAGE (Generic Desktop)
          09 06  # USAGE (Keyboard)
          a1 01  # COLLECTION (Application)

          05 07  #   USAGE_PAGE (Key Codes)
          19 e0  #   USAGE_MINIMUM (224)
          29 e7  #   USAGE_MAXIMUM (231)
          15 00  #   LOGICAL_MINIMUM (0)
          25 01  #   LOGICAL_MAXIMUM (1)
          75 01  #   REPORT_SIZE (1)
          95 08  #   REPORT_COUNT (8)
          81 02  #   INPUT (Data, Variable, Absolute)

          95 01  #   REPORT_COUNT (1)
          75 08  #   REPORT_SIZE(8)
          81 03  #   INPUT (Constant)

          95 05  #   REPORT_COUNT (5)
          75 01  #   REPORT_SIZE(1)
          05 08  #   USAGE_PAGE (Page# for LEDs)
          19 01  #   USAGE_MINIMUM (1)
          29 05  #   USAGE_MAXIMUM (5)
          91 02  #   OUTPUT (Data, Variable, Absolute)

          95 01  #   REPORT_COUNT(1)
          75 03  #   REPORT_SIZE(3)
          91 01  #   OUTPUT (Constant)

          95 06  #   REPORT_COUNT (6)
          75 08  #   REPORT_SIZE (8)
          15 00  #   LOGICAL_MINIMUM (0)
          25 65  #   LOGICAL_MAXIMUM (101)
          05 07  #   USAGE_PAGE (Key Codes)
          19 00  #   USAGE_MINIMUM (0)
          29 65  #   USAGE_MAXIMUM (101)
          81 00  #   INPUT (Data, Array)

          c0     # END_COLLECTION
        ''}
        echo 8 > ${gadget}/functions/hid.usb0/report_length
        ln -s ${gadget}/functions/hid.usb0 ${gadget}/configs/c.1

        # Setup Mouse
        mkdir -p ${gadget}/functions/hid.usb1
        echo 2 > ${gadget}/functions/hid.usb1/protocol
        echo 1 > ${gadget}/functions/hid.usb1/subclass
        # hid boot mouse decriptor
        cat >${gadget}/functions/hid.usb1/report_desc <${writeReportDescriptor ''
          05 01  # USAGE_PAGE (Generic Desktop)
          09 02  # USAGE (Mouse)
          a1 01  # COLLECTION (Application)
          09 01  #   USAGE (Pointer)
          a1 00  #   COLLECTION (Physical)

          05 09  #     USAGE_PAGE (Button)
          19 01  #     USAGE_MINIMUM (Button 1)
          29 03  #     USAGE_MAXIMUM (Button 3)
          15 00  #     LOGICAL_MINIMUM (0)
          25 01  #     LOGICAL_MAXIMUM (1)
          95 03  #     REPORT_COUNT (3)
          75 01  #     REPORT_SIZE (1)
          81 02  #     INPUT (Data, Variable, Absolute)
          95 01  #     REPORT_COUNT (1)
          75 05  #     REPORT_SIZE (5)
          81 01  #     INPUT (Constant)

          05 01  #     USAGE_PAGE (Generic Desktop)
          09 30  #     USAGE (X)
          09 31  #     USAGE (Y)
          09 38  #     USAGE (Wheel)
          15 81  #     LOGICAL_MINIMUM (-127)
          25 7f  #     LOGICAL_MAXIMUM (127)
          75 08  #     REPORT_SIZE (8)
          95 03  #     REPORT_COUNT (3)
          81 06  #     INPUT (Data, Variable, Relative)

          c0     #   ENC_COLLECTION
          c0     # ENC_COLLECTION
        ''}
        echo 4 > ${gadget}/functions/hid.usb1/report_length
        ln -s ${gadget}/functions/hid.usb1 ${gadget}/configs/c.1

        ## Setup Audio
        #mkdir -p ${gadget}/functions/uac2.usb0
        #ln -s ${gadget}/functions/uac2.usb0 ${gadget}/configs/c.1

        echo ${udc} > ${gadget}/UDC
      '';
      ExecStop = pkgs.writeShellScript "unconfigure-usb-gadget" ''
        echo "" > ${gadget}/UDC
        rm ${gadget}/configs/*/*.usb*
        rmdir ${gadget}/configs/*
        rmdir ${gadget}/functions/*
        rmdir ${gadget}/strings/*
        rmdir ${gadget}
      '';
    };
  };

}
