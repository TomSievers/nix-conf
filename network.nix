{ config, pkgs, ... }:

{
  # Configure networkmanager.
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  # Make sure to use resolvconf
  networking.resolvconf.enable = true;

  hardware.enableRedistributableFirmware = true;

  # Default hostname
  networking.hostName = "nixos";

  networking.extraHosts = ''
    192.168.2.9 cam1.home.arpa
    192.168.2.9 cam2.home.arpa
    192.168.2.9 cam3.home.arpa
  '';

  # Enable mDNS and Avahi for local network service discovery.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # Enable CUPS to print documents.
  services.printing = {
    enable = true;
    webInterface = true;
    drivers = [
      pkgs.gutenprint
      pkgs.gutenprintBin
      pkgs.hplip
      pkgs.hplipWithPlugin
      pkgs.cnijfilter2
    ];
  };

  # Allow unfree packages, which may be needed for some hardware drivers and firmware.
  nixpkgs.config.allowUnfree = true;
}
