{ lib, config, pkgs, mkTrivialModule, ... }:

mkTrivialModule {
  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  security.rngd.enable = lib.mkDefault false;

  # Restore systemd default
  services.logind.killUserProcesses = lib.mkDefault true;

  console.keyMap = "de-latin1-nodeadkeys";
  time.timeZone = "Europe/Berlin";

  boot.tmpOnTmpfs = true;

  services = {
    openssh.enable = true;
    dbus.enable = true;
    acpid.enable = true;
    avahi.enable = true;
  };

  programs = {
    less.enable = true;
    mtr.enable = true;
    tmux.enable = true;
  };

  programs.zsh = {
    enable = true;
    promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    interactiveShellInit = ''
      source ${config.nix.package.src}/misc/zsh/completion.zsh
    '';
    shellInit = ''
      command -v direnv >/dev/null && eval "$(direnv hook zsh)"
    '';
  };

  environment.shellInit = ''
    PATH=~/.local/bin:$PATH
    export PATH
  '';

  users.mutableUsers = false;
  users.users.beinke = {
    uid = 1000;
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    hashedPassword = "$6$rounds=424242$4XeOOipFMr154yFt$duKTFu2mSR9LnrGILjgumlxl8FltvCo9RBjhWi1N56avEVaAJym3LFlw3y2.JMCVYAO2ZpK75eF7B/7cSu5rR0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCC4cFL1xcZOsIzXg1b/M4b89ofMKErNhg9s+0NdBVC beinke@th1"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCC4cFL1xcZOsIzXg1b/M4b89ofMKErNhg9s+0NdBVC beinke@th1"
  ];

  nix.autoOptimiseStore = true;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.package = pkgs.nixUnstable;

  environment.systemPackages = with pkgs; [
    git
    gnupg
    htop
    inxi-full
    kitty.terminfo
    lm_sensors
    magic-wormhole
    neovim-queezle
    ripgrep
    tig
  ];
}
