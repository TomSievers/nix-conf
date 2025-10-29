{ config, pkgs, ... }:

{
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "2";
      configurationLimit = 10;
    };
    efi.canTouchEfiVariables = true;
  };
}
