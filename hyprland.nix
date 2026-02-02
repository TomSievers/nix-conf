{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.de.hyprland;
  hmAvailable = config ? home-manager && config.home-manager ? users;
  username = config.user.username or null;
  confDir = ./conf;
in {
  options.de.hyprland = {
    enable = mkEnableOption "Enable hyprland DE";
    withHomeManager = mkOption {
      type = types.bool;
      default = true;
      description = "Also configure hyprland in home-manager for the user.";
    };
  };

  config = mkIf (cfg.enable) {
    # Enable hyprland and related programs
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # Enable related programs
    programs.waybar.enable = true;
    programs.hyprlock.enable = true;
    services.hypridle.enable = true;

    # Install hyprland related packages
    environment.systemPackages = with pkgs; [
      rofi
      kitty
      pyprland
      hyprpicker
      hyprpaper
      hyprsunset
      hyprpolkitagent
      hyprsysteminfo
    ];

    # Also configure hyprland in home-manager if requested and available
    home-manager.users =
      mkIf (hmAvailable && cfg.withHomeManager && username != null) {
        ${username} = { pkgs, ... }: {
          wayland.windowManager.hyprland.enable = true;
          programs.waybar.enable = true;

          # Hint for using wayland instead of X
          home.sessionVariables.NIXOS_OZONE_WL = "1";

          # Install hyprland config files
          home.file = {
            ".config/hypr".source = "${confDir}/hypr";
            ".config/xdg-desktop-portal".source =
              "${confDir}/xdg-desktop-portal";
            "Pictures/Wallpapers".source = "${confDir}/wallpapers";
          };
        };
      };
  };
}
