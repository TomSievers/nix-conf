{ config, pkgs, ... }:

{
  # Install firefox
  programs.firefox.enable = true;
  programs.vim.enable = true;

  # Allow nonfree packages like vscode
  nixpkgs.config.allowUnfree = true;

  # Enable libvirtd for virtualisation and virt-manager GUI
  virtualisation.libvirtd = {
    qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    enable = true;
  };
  programs.virt-manager.enable = true;

  programs.wireshark.enable = true;

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
    (python3.withPackages (
      ps: with ps; [
        tkinter
        pip
        virtualenv
        pyserial
        pygobject3
        numpy
        scipy
        matplotlib
        notebook
        jupyter
      ]
    ))
    stlink
    openocd

    wineWow64Packages.stable
    winetricks

    nixfmt

    gparted
    stm32cubemx
    minicom
    pyocd
    teams-for-linux
    ghidra
    arduino-ide
    libreoffice-fresh
    wireguard-tools
    wg-netmanager
    spotify
    wireshark
    inspectrum
    claude-code

    gcc
    rtl-sdr

    pkgs.pkgsStatic.qemu-user
  ];

  hardware.rtl-sdr.enable = true;

  # Enable steam
  programs.steam.enable = true;

  services.udev.packages = with pkgs; [
    stlink
    openocd
    probe-rs-tools
  ];

  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "armv7l-linux"
    "armv6l-linux"
  ];

  boot.binfmt.preferStaticEmulators = true;
}
