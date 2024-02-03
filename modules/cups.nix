{
  mkTrivialModule,
  pkgs,
  ...
}:
mkTrivialModule {
  services.printing = {
    enable = true;
    drivers = [pkgs.cups-kyocera-ecosys-m552x-p502x];
  };
  hardware.printers.ensurePrinters = [
    {
      name = "dimitri";
      model = "Kyocera/Kyocera ECOSYS P5021cdw.PPD";
      deviceUri = "socket://192.168.1.29:9100";
    }
  ];
}
