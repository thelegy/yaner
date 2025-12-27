{
  writeScript,
  btrfs-progs,
  coreutils,
  util-linux,
  zsh,
}:

writeScript "backup_snapshot" ''
  #!${zsh}/bin/zsh

  path+=${btrfs-progs}/bin
  path+=${coreutils}/bin
  path+=${util-linux}/bin

  ${builtins.readFile ./snapshot.zsh}
''
