#!/usr/bin/env zsh

set -euo pipefail

fstype() findmnt -rnUo FSTYPE $1

submountpoints() {
  local prefix=\0
  for mp in $(findmnt -rRno TARGET $1); {
    if [[ $mp == $1 ]] continue
    mp=$mp/
    if [[ ${mp#$prefix} != $mp ]] continue
    if [[ $mp =~ "^/.backup/" ]] continue
    if [[ $mp =~ "/.backup-snapshot." ]] continue
    prefix=$mp
    echo $mp
  }
}

btrfs_subvolumes() {
  for name in $(btrfs subvolume list -o $1 | cut -d' ' -f9); {
    if { ! btrfs subvolume show ${1#/}/${name#*/} >/dev/null 2>&1 } continue
    if [[ $name =~ "/.backup-snapshot." ]] continue
    if [[ $name =~ "/.backup$" ]] continue
    echo ${name#*/}
  }
}

btrfs_snapshot_name() echo ${src%/}/.backup-snapshots/_.${(j|.|)${(s|/|)1:-}}

btrfs_snapshot() {
  readonly snapshot=$(btrfs_snapshot_name ${1:-/})
  if [[ -e $snapshot ]] {
    btrfs subvolume delete $snapshot
  }
  btrfs subvolume snapshot -r ${src%/}/${1:-} $snapshot
}

bindmount() mount --bind --read-only $1 $2

prepare_btrfs() {
  if { btrfs subvolume show $src >/dev/null 2>&1 } {
    subvolumes=( $(btrfs_subvolumes $src) )
    mkdir -p ${src%/}/.backup-snapshots
    for subvol in '' $subvolumes; {
      btrfs_snapshot $subvol
    }
    for subvol in '' $subvolumes; {
      snapshot=$(btrfs_snapshot_name $subvol)
      bindmount $snapshot ${dst%/}/$subvol
    }
  }
  for mp in $(submountpoints $src); {
    prepare $mp $dst/${mp#$src}
  }
}

prepare_bind() bindmount $src $dst

prepare() {
  readonly src=/${${1%/}#/}
  readonly dst=/${${2%/}#/}
  fs=$(fstype $src)
  case $fs {
    btrfs) prepare_btrfs ;;
    *) prepare_bind ;;
  }
}

cleanup() {
  for mp in $(findmnt -rRUno TARGET $1 | tac); {
    umount $mp || true
  }
}

mkdir -p /.backup
cleanup /.backup
prepare / /.backup
