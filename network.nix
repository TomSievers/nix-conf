{ config, pkgs, ... }:

{
  # Configure networkmanager.
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  # Make sure to use resolvconf
  networking.resolvconf.enable = true;

  hardware.enableRedistributableFirmware = true;
}
