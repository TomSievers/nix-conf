# Configuration shared by every host. Host-specific settings live in
# hosts/<name>/configuration.nix.

{ ... }:

{
  imports = [
    ../modules/system/nix-settings.nix
    ../modules/system/boot.nix
    ../modules/system/audio.nix
    ../modules/system/locale.nix
    ../modules/system/network.nix
    ../modules/system/power.nix
    ../modules/system/packages.nix
    ../modules/system/virtualisation.nix
    ../modules/system/embedded.nix
    ../modules/system/nix-gc-comprehensive.nix
    ../modules/system/update-check.nix
    ../modules/desktop/gnome.nix
    ../modules/desktop/hyprland.nix
    ../modules/user.nix
  ];

  time.timeZone = "Europe/Amsterdam";

  user = {
    enable = true;
    username = "tom";
    description = "Tom S";
    zshTheme = "agnoster";
  };

  services.nix-gc-comprehensive.enable = true;
  services.flake-update-check.enable = true;
}
