{ mkTrivialModule
, pkgs
, lib
, ... }:
with lib;

let
  jobName = "yaner-prebuild";
  author = "${jobName} automated job";
  postfix = "update-nixpkgs";
  script = pkgs.writeScript jobName ''
    #!${pkgs.zsh}/bin/zsh
    set -euo pipefail

    export XDG_CACHE_HOME=$CACHE_DIRECTORY
    export GNUPGHOME=$STATE_DIRECTORY/.gnupg
    export GIT_CONFIG_GLOBAL=${git_config}
    export EMAIL=${jobName}-on-$HOST@janbeinke.com

    readonly sshDir=$STATE_DIRECTORY/.ssh
    mkdir -p $sshDir
    chmod 700 $sshDir
    if [[ ! -e $sshDir/id_ed25519 ]] {
      ssh-keygen -t ed25519 -q -f $sshDir/id_ed25519 -P "" -C "${jobName} on $HOST"
      cat $sshDir/id_ed25519.pub
    }

    cd $RUNTIME_DIRECTORY

    gpg --quiet --trust-model always --import ${./pubkey.asc}

    gpg --quiet --no --batch --passphrase "" --quick-generate-key "${author} <$EMAIL>" || true
    gpg --quiet --export --armor "${author} <$EMAIL>" > $GNUPGHOME/pubkey.asc

    git clone --depth 1 --no-single-branch git@github.com:thelegy/yaner.git
    cd yaner

    compare_results() {
      branch=$1
      updateBranch=$branch-${postfix}
      if ! {git rev-parse origin/$updateBranch &>/dev/null} {
        # remote branch does not exist yet
        return 0
      }
      if [[ $(git rev-parse origin/$branch) == $(git rev-parse origin/$updateBranch) ]] {
        # update branch was merged, so restrictions were lifted
        return 0
      }
      oldBuildOutput=$(git show --pretty=format:"%B" --no-patch origin/$updateBranch | tail -n+4)
      if [[ $2 == $oldBuildOutput ]] {
        # exactly the same build result, test if repo was changed
        if {git diff origin/$updateBranch --quiet --exit-code} {
          # nothing was changed, suppress commit
          return 1
        }
        return 0
      }

      typeset -A results oldResults
      for result in ''${(f)2}; {
        results[$(cut -d' ' -f 3- <<< $result)]=$(cut -d' ' -f 1 <<< $result)
      }
      for result in ''${(f)oldBuildOutput}; {
        oldResults[$(cut -d' ' -f 3 <<< $result)]=$(cut -d' ' -f 1 <<< $result)
      }

      for target in ''${(k)results}; {
        if (( $results[$target] > ''${oldResults[$target]:-255} )) {
          # detected a target that got worse, forbid continuation
          return 1
        }
      }

      return 0
    }

    for branch in $(git branch --format '%(refname:strip=2)'); {
      [[ $branch == *-${postfix} ]] && continue
      if {git verify-commit $branch} {
        echo Build for branch '"'$branch'"'
        git switch $branch
        nix flake lock --update-input nixpkgs
        buildResult=$(nix run .#prebuild-script) || true
        echo $buildResult
        if {compare_results $branch $buildResult} {
          echo "Update nixpkgs\n\nAutomated build result:\n$buildResult" |git commit -a -F -
          git push --force-with-lease origin HEAD:refs/heads/$branch-${postfix} || true
        }
      }
    }
  '';
  ssh_config = pkgs.writeText "ssh_config" ''
    Include /etc/ssh/ssh_config.orig
    IdentityFile /var/lib/${jobName}/.ssh/id_ed25519
  '';
  git_config = pkgs.writeText "git_config" ''
    [user]
      name = ${author}

    [commit]
      gpgSign = true
  '';
in
mkTrivialModule {

  systemd.services.yaner-prebuild = {
    startAt = "*:00";
    path = with pkgs; [
      git
      gnupg
      lix
      openssh
      strace
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${script}";
      Restart = "on-failure";
      DynamicUser = true;
      ProtectHome = "tmpfs";
      RuntimeDirectory = jobName;
      CacheDirectory = jobName;
      StateDirectory = jobName;
      StateDirectoryMode = "0700";
      BindReadOnlyPaths = [
        "/etc/ssh/ssh_config:/etc/ssh/ssh_config.orig"
        "${ssh_config}:/etc/ssh/ssh_config"
        "${./known_hosts}:/etc/ssh/ssh_known_hosts"
      ];
      ReadWritePaths = [
        "/nix/var/nix/daemon-socket/"
      ];
      RestartSec = "10s";
      RestartMaxDelaySec = "1h";
      RestartSteps = 4;
      TimeoutStartSec = "2h";
    };
  };

}
