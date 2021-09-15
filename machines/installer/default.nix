{ mkMachine, ... }:

mkMachine {} ({ pkgs, modulesPath, ... }: {

  imports = [
    (modulesPath + "/installer/cd-dvd/iso-image.nix")
    (modulesPath + "/profiles/all-hardware.nix")
  ];

  isoImage.makeEfiBootable = true;
  isoImage.makeUsbBootable = true;

  boot.kernelPackages = pkgs.linuxPackages_testing_bcachefs;

  wat.thelegy.base.enable = true;

  services.greetd = {
    enable = true;
    restart = true;
    settings.default_session = {
      command = pkgs.writeScript "tmux-session" ''
        ${pkgs.tmux}/bin/tmux  \
          new -d -s greeter '${pkgs.htop}/bin/htop; zsh' \; \
          split-window -h -l 80 '${pkgs.procps}/bin/watch -t -c ${pkgs.inxi}/bin/inxi -MiBDpo -c2; zsh' 2>/dev/null
        ${pkgs.tmux}/bin/tmux attach -t greeter -r 2>/dev/null
      '';
      user = "root";
    };
  };

})
