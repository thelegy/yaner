{ writeScript
, zsh
}:

writeScript "backup_snapshot" ''
  #!${zsh}/bin/zsh

  ${builtins.readFile ./snapshot.zsh}
''
