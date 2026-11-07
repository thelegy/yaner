{
  mkTrivialModule,
  pkgs,
  lib,
  ...
}:
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
      report=$2
      previousReport=$RUNTIME_DIRECTORY/previous-results.json
      rm -f $previousReport
      if git rev-parse --verify origin/$updateBranch &>/dev/null && \
          [[ $(git rev-parse origin/$branch) != $(git rev-parse origin/$updateBranch) ]]; then
        git show --pretty=format:"%B" --no-patch origin/$updateBranch | tail -n+4 > $previousReport
        python3 ${./compare-results.py} $report $previousReport
      else
        python3 ${./compare-results.py} $report
      fi
    }

    for branch in $(git branch --format '%(refname:strip=2)'); {
      [[ $branch == *-${postfix} ]] && continue
      if {git verify-commit $branch} {
        echo Build for branch '"'$branch'"'
        git switch $branch
        nix flake lock --update-input nixpkgs
        report=$RUNTIME_DIRECTORY/build-results.json
        rm -f $report
        nix develop -c wat build --all --results-file $report || true
        if buildResult=$(compare_results $branch $report); then
          # Avoid duplicate commits when neither the lock nor host outcomes changed.
          if git rev-parse --verify origin/$branch-${postfix} &>/dev/null && \
              git diff origin/$branch-${postfix} --quiet --exit-code && \
              [[ $buildResult == $(git show --pretty=format:"%B" --no-patch origin/$branch-${postfix} | tail -n+4) ]]; then
            continue
          fi
          printf '%s\n\n%s\n%s\n' "Update nixpkgs" "Automated build result:" "$buildResult" |git commit -a -F -
          git push --force-with-lease origin HEAD:refs/heads/$branch-${postfix} || true
        else
          resultStatus=$?
          # Missing, malformed or incomplete reports are infrastructure failures.
          if (( resultStatus != 1 )) {
            exit 1
          }
        fi
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
      python3
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
