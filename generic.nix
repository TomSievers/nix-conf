{ config, pkgs, ... }:

{
  # Enable nix-command experimental features.
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
