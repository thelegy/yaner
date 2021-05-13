{ lib, ... }:
with lib;

{

  hardware.deviceTree.overlays = [
    {
      name = "rockpro-fan";
      dtsText = ''
        /dts-v1/;
        /plugin/;
        / {
          compatible = "pine64,rockpro64";
        };
        &fan {
          #cooling-cells = <0x02>;
          cooling-min-state = <0>;
          cooling-max-state = <4>;
          cooling-levels = <0 80 102 170 230>;
        };
        &cpu_thermal {
          trips {
            cpu_warm: cpu_warm {
              temperature = <55000>;
              hysteresis = <15000>;
              type = "active";
            };
          };
          cooling-maps {
            map10 {
              trip = <&cpu_warm>;
              cooling-device = <&fan 0x00 0x01>;
            };
            map11 {
              trip = <&cpu_alert0>;
              cooling-device = <&fan 0x01 0x02>;
            };
            map12 {
              trip = <&cpu_alert1>;
              cooling-device = <&fan 0x02 0x03>;
            };
            map13 {
              trip = <&cpu_crit>;
              cooling-device = <&fan 0x03 0x04>;
            };
          };
        };
      '';
    }
  ];

}
