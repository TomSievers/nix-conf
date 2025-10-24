{ config, pkgs, ... }:

{
  # Configure networkmanager.
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = true;
  # Make sure to use resolvconf
  networking.resolvconf.enable = true;
}
