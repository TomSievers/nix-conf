{ config, lib, ... }:

with lib;

{
  options.nixConf.flakeDir = mkOption {
    type = types.str;
    default = "/etc/nixos/nix-conf";
    description = ''
      Absolute path of the local checkout of this flake. Used by the shell
      aliases and exported as $NIXOS_FLAKE_DIR, so nothing depends on the
      current directory or on a fixed checkout location.
    '';
  };

  config = {
    # Enable nix-command experimental features.
    nix.extraOptions = ''
      experimental-features = nix-command flakes
    '';

    environment.sessionVariables.NIXOS_FLAKE_DIR = config.nixConf.flakeDir;
  };
}
