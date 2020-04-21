{ config, channels, lib, pkgs, ... }:

with lib;

let

  cfg = config.legy.docpages;
  page_cfgs = attrValues cfg.pages;

  perDocpageConfig = {name, ...}: {
    options = {
      tag = mkOption {
        type = types.str;
      };
      repo = mkOption {
        type = types.str;
      };
      repo_dir = mkOption {
        type = types.str;
      };
      target_dir = mkOption {
        type = types.str;
        default = cfg.target_dir;
      };
    };
    config = {
      tag = mkDefault name;
      repo_dir = mkDefault ("/tmp/docpagerepo-" + (builtins.hashString "sha1" cfg.pages."${name}".repo));
    };
  };

  flattenList = l: builtins.foldl' (x: y: x//y) {} l;

  docpageService = docpageCfg: {
    "docpage_${docpageCfg.tag}" = {
      description = "Generator for the docpage of ${docpageCfg.tag}";
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [ git nix ];
      environment."NIX_PATH" = "nixpkgs=${channels.nixos-unstable}";
      script = ''
        git clone --bare ${docpageCfg.repo} ${docpageCfg.repo_dir} || true
        readonly tempdir=$(mktemp -d)
        trap "rm -rf $tempdir" EXIT INT HUP TERM
        GIT_DIR=${docpageCfg.repo_dir} git fetch --tags
        GIT_DIR=${docpageCfg.repo_dir} GIT_WORK_TREE=$tempdir git checkout --force --ignore-other-worktrees --quiet ${docpageCfg.tag}
        mkdir -p ${docpageCfg.target_dir}
        nix-build --out-link ${docpageCfg.target_dir}/${docpageCfg.tag} --attr ${docpageCfg.tag} $tempdir/docpages.nix
      '';
    };
  };

  docpageTimer = docpageCfg: {
    "docpage_${docpageCfg.tag}" = {
      description = "Update timer for the generator of ${docpageCfg.tag}";
      wantedBy = [ "multi-user.target" ];
      requires = [ "network-online.target" ];
      after = [ "network-online.target" ];
      timerConfig = {
        Unit = "docpage_${docpageCfg.tag}.service";
        OnCalendar = "hourly";
        AccuracySec = "1h";
        RandomizedDelaySec = "1h";
      };
    };
  };

in {

  options.legy.docpages.pages = mkOption {
    type = with types; loaOf (submodule perDocpageConfig);
    default = {};
  };

  options.legy.docpages.target_dir = mkOption {
    type = types.str;
  };

  config = {
    systemd.services = flattenList (map docpageService page_cfgs);
    systemd.timers = flattenList (map docpageTimer page_cfgs);
  };

}
