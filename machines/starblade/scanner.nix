{
  config,
  lib,
  pkgs,
  ...
}:
let
  devName = "fujitsu:ScanSnap S1500:36798";
  consumeDir = config.services.paperless.consumptionDir;
  buttonOption = "scan";
  python = pkgs.python3.withPackages (ps: [
    ps.pillow
    ps.sane
  ]);
  scanScript = pkgs.writeScript "scan-to-paperless.py" ''
    #!${python}/bin/python

    import _sane
    import logging
    import os
    import sane
    import sys
    import time

    from PIL import ImageFilter, ImageStat
    from datetime import datetime


    class Scanner:
      BUTTON_OPTION = '${buttonOption}'
      CONSUME_DIR = '${consumeDir}'
      POLL_RATE = .25
      RESOLUTION = 300

      def prepare_scan(self):
        self.dev.resolution = self.RESOLUTION
        self.dev.mode = 'Color'
        self.dev.source = 'ADF Duplex'
        self.dev.page_height = 420
        self.dev.swskip = 0.5
        self.dev.swcrop = True

      def __init__(self):
        sane.init()
        try:
          self.dev = sane.open('${devName}')
        except _sane.error:
          logging.warning('Failed to create device. Scanner may be turned off. Shutdown')
          sys.exit(0)
        logging.info('Sane started')

      def get_option(self, option: str):
        return self.dev.dev.get_option(self.dev[option].index)

      def wait_for_button(self):
        logging.info('Awaiting button press...')
        previous = True
        while True:
          time.sleep(self.POLL_RATE)
          try:
            button = bool(self.get_option(self.BUTTON_OPTION))
            if button and not previous:
              return
            previous = button
          except _sane.error:
            logging.warning('Failed to get button, printer was probably turned off. Shutdown')
            sys.exit(0)

      def is_blank_page(self, image):
        edges = image.convert('L').reduce(4).filter(ImageFilter.FIND_EDGES)
        edgesSize = 1.0 * edges.width * edges.height
        hist = edges.histogram()
        x = sum(hist[64:]) / edgesSize
        logging.info(f'{x=}')
        if x < 0.01:
          return True
        return False

      def scan(self):
        logging.info('Start scanning...')
        self.prepare_scan()
        pages = []
        for page in self.dev.multi_scan():
          logging.debug('Scanned page')
          if BlankDetector(page).blank():
            logging.debug('Omitting blank page')
            continue
          pages.append(page)
        logging.debug(f'Scanned document with {len(pages)} pages')
        if len(pages) == 0:
          logging.warning('Scanned empty document')
          return
        if len(pages) >= 1:
          fileName = f'scan_{datetime.now().strftime('%Y%m%d-%H%M%S')}.pdf'
          logging.info(f'Scanned document with {len(pages)} pages: {fileName}')
          pages[0].save(f'{self.CONSUME_DIR}/{fileName}', save_all=True, append_images=pages[1::], resolution=self.RESOLUTION)

      def main(self):
        while True:
          self.wait_for_button()
          self.scan()


    class BlankDetector:
      def __init__(self, image):
        self.image = image
        self.image_L4 = image.convert('L').reduce(4)

      def blank(self):
        return self.test_edges()

      def test_edges(self):
        edges = self.image_L4.filter(ImageFilter.FIND_EDGES)
        edgesSize = 1.0 * edges.width * edges.height
        hist = edges.histogram()
        x = sum(hist[64:]) / edgesSize
        logging.debug(f'{x=}')
        if x < 0.01:
          return True
        return False


    if __name__ == '__main__':
      logging.basicConfig(level=logging.INFO)
      os.umask(0o007)
      Scanner().main()
  '';
in
{

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "scansnap-firmware"
    ];

  hardware.sane = {
    enable = true;
    drivers.scanSnap.enable = true;
  };

  systemd.services.scan-to-paperless = {
    serviceConfig = {
      ExecStart = scanScript;
      Restart = "on-failure";

      SyslogIdentifier = "scan-to-paperless";

      # Run unprivileged
      DynamicUser = true;
      Group = "paperless-consume";
      SupplementaryGroups = [ "scanner" ];

      ReadWritePaths = [ consumeDir ];

      DeviceAllow = [ "char-usb_device rw" ];

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectControlGroups = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      LockPersonality = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      RestrictNamespaces = true;
      SystemCallArchitectures = "native";
    };
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="04c5", ATTR{idProduct}=="11a2", TAG+="systemd", ENV{SYSTEMD_WANTS}+="scan-to-paperless.service"
  '';

}
