# wat-legacy build baseline

Commit: `377bb470cb914f37db3690b33da6f1a56c164ac2` (`dns: Add paperless ingress`).
Run: 2026-11-11T11:28:23.723318+00:00 to 2026-11-11T12:20:36.111190+00:00.
Committed flake.lock SHA-256: `deeb981a7b222497f8ec99a49043ef9e141edceac22f9467c05a45c1c46425a7`.

Nine successful builds, one evaluation failure, two builds interrupted after a stalled dependency fetch.

Built from a clean isolated Git checkout with its original lock file. No configuration fixes or input updates were applied. The legacy revision predates the `wat` CLI, so builds used:

```sh
nix build --no-link --json --keep-going .#nixosConfigurations.<host>.config.system.build.toplevel
```

Hashes are the 32-character Nix store-path prefixes, not content hashes. Paths marked “expected only” were evaluated but were not successfully built.

| System | Result | System output path |
| --- | --- | --- |
| agony | built | `/nix/store/lficq5250pnry146f9ap45vhvbx5891l-nixos-system-agony-25.11.20251226.f560cce` |
| forever | built | `/nix/store/m4yds5hqwk6fmh63bfma6vas6pn86ivl-nixos-system-forever-26.05.20251225.3e2499d` |
| incus-test | built | `/nix/store/cma2sfgmffxis8j37ql5avg2ly1zi3sm-nixos-system-incus-test-26.05.20251225.3e2499d` |
| installer | built | `/nix/store/va45l23kmvq7ng0h729ydny4wnl1d40f-nixos-system-installer-26.05.20251225.3e2499d` |
| lll | evaluation failed | — |
| mininet | built | `/nix/store/q9l5ajxn7fmkkg8aabiwmrkbcv6wvk3m-nixos-system-mininet-26.05.20251225.3e2499d` |
| nix-test | built | `/nix/store/vpm6sjs2viz4diih66lhwk6y8c738mbv-nixos-system-nix-test-26.05.20251225.3e2499d` |
| nixroute | built | `/nix/store/yczgr9fgy0pd3bqp5h8xa99k2iqsc3y9-nixos-system-nixroute-26.05.20251225.3e2499d` |
| sirrah | fetch blocked; expected only | `/nix/store/5c8kcg8n79ns5xykzjrgbbhlviygpfkp-nixos-system-sirrah-26.05.20251225.3e2499d` |
| starblade | built | `/nix/store/h56l8lhs7bd4v75ji0c945lidjckz0ck-nixos-system-starblade-25.11.20251226.f560cce` |
| th1 | fetch blocked; expected only | `/nix/store/k19k7scaqikamxy70acpw2r0z4qk27j0-nixos-system-th1-26.05.20251225.3e2499d` |
| y | built | `/nix/store/9z2jdkic8c58cr3vmlialkrfhyl336lr-nixos-system-y-26.05.20251225.3e2499d` |

## Failures and blockers

- `lll`: nixpkgs rejects the removed `services.xserver.desktopManager.plasma5` option. No system output was produced.
- `sirrah`, `th1`: `typst-languagetool-head-vendor-staging` stalled on the first five crates.io downloads (`addr2line`, `biblatex`, `clap`, `filetime`, `csv`). The agent interrupted these builds; their evaluated output paths above do not establish successful builds.

Complete logs and the isolated checkout are in `/tmp/yaner-wat-legacy-baseline`. Machine-readable results are in `wat-legacy-builds.json`.
