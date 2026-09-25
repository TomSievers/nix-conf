# Usage

This repo is a flake with one NixOS configuration per host in `hosts/<name>/`.

1. Clone it anywhere (e.g. `/etc/nixos/nix-conf`).
2. If the checkout is not at `/etc/nixos/nix-conf`, set `nixConf.flakeDir` in
   `hosts/<name>/configuration.nix` to the checkout path.
3. First build: `sudo nixos-rebuild switch --flake <checkout>#<host>`.

After that, the shell aliases work from any directory:

- `update`: rebuild the current host.
- `system-upgrade`: update all flake inputs, then rebuild.
- `nix-bump-unstable`: update only `nixpkgs-unstable`, then rebuild.
- `system-clean`: delete old generations and collect garbage.

## Layout

```
flake.nix               hosts + overlays
hosts/common.nix        imports and settings shared by every host
hosts/<name>/           per-host config, hardware config, host-only extras
modules/system/         NixOS modules (boot, network, power, packages, ...)
modules/desktop/        desktop environments (gnome, hyprland)
modules/user.nix        the user account and its home-manager config
conf/ wallpapers/ patches/   files referenced by the modules
```

Packages: system/root-level tools go in `modules/system/packages.nix`, user
applications in `home.packages` in `modules/user.nix`, project toolchains in a
project devshell or devcontainer.
