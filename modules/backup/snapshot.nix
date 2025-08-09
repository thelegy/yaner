{
  writeScript,
  btrfs-progs,
  coreutils,
  utillinux,
  zsh,
}:

writeScript "backup_snapshot" ''
  #!${zsh}/bin/zsh

  path+=${btrfs-progs}/bin
  path+=${coreutils}/bin
  path+=${utillinux}/bin

  ${builtins.readFile ./snapshot.zsh}
''
