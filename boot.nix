{ config, pkgs, ... }:

{
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  # Enable plymouth boot logo.
  boot.plymouth = { enable = true; };
}
