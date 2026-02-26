{ config, pkgs, ... }:

{
  # Install firefox
  programs.firefox.enable = true;
  programs.vim.enable = true;

  # Allow nonfree packages like vscode
  nixpkgs.config.allowUnfree = true;

  # Enable libvirtd for virtualisation and virt-manager GUI
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  # Enable mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Allows resolving .local hostnames
    openFirewall = true; # Opens ports for mDNS discovery
  };

  # Enable GVFS for mounting network shares in file managers
  services.gvfs.enable = true;

  environment.systemPackages = with pkgs; [
    podman-compose
    # Default command line tools
    curl
    wget
    bmaptool
    rpiboot
    parted
    ncdu
    avrdude
    probe-rs-tools
    jq
    git
    gcc-arm-embedded
    python312
    dfu-util
    stlink
    openocd

    nixfmt-classic

    nerd-fonts.adwaita-mono

    gparted
    solaar
    logitech-udev-rules
    gnomeExtensions.solaar-extension
    stm32cubemx
    minicom
    pyocd
    teams-for-linux
    ghidra
    arduino-ide
  ];

  # Enable steam
  programs.steam.enable = true;

  services.udev.packages = with pkgs; [ stlink openocd probe-rs-tools ];

  boot.binfmt.emulatedSystems =
    [ "aarch64-linux" "armv7l-linux" "armv6l-linux" ];

  boot.binfmt.preferStaticEmulators = true;
}
