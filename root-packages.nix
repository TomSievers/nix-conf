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
    python312
    python312Packages.pipx

    nixfmt-classic

    nerd-fonts.adwaita-mono

    gparted
    solaar
    logitech-udev-rules
    gnomeExtensions.solaar-extension
    stm32cubemx
    minicom
  ];

  # Enable steam
  programs.steam.enable = true;
}
