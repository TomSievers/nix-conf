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

  config = mkIf cfg.hyprland {
    # Enable hyprland and related programs
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };

    # Enable related programs
    programs.kitty.enable = true;
    programs.waybar.enable = true;
    programs.hyprlock.enable = true;
    services.hypridle.enable = true;
    

    # Install hyprland related packages
    environment.systemPackages = with pkgs; [
      pyprland
      hyprpicker
      hyprcursor
      hyprpaper
      hyprsunset
      hyprpolkitagent
      hyprsysteminfo
    ];

    # Also configure hyprland in home-manager if requested and available
    home-manager.users = mkIf (hmAvailable && cfg.withHomeManager && username != null) ? {
      ${username} = { pkgs, ... }:
        {
          wayland.windowManager.hyprland.enable = true;
          programs.waybar.enable = true;

          # Hint for using wayland instead of X
          home.sessionVariables.NIXOS_OZONE_WL = "1";

          # Install hyprland config files
          home.file = {
            ".config/hypr".source = "${confDir}/hypr";
            ".config/xdg-desktop-portal".source = "${confDir}/xdg-desktop-portal";
            "Pictures/Wallpapers".source = "${confDir}/wallpapers";
          };
        };
    };
  };
}

# { config, lib, pkgs, ... }:

# let
#   cfg = config.services.hyprland;
#   hmAvailable = config ? home-manager && config.home-manager ? users;
#   username = config.user.username or null;

#   # Directory containing all Hyprland config fragments
#   hyprDir = ./hypr;
# in
# {
#   options.services.hyprland = {
#     enable = lib.mkEnableOption "Enable Hyprland compositor";

#     enableHomeManagerConfig = lib.mkOption {
#       type = lib.types.bool;
#       default = true;
#       description = "Whether to configure Hyprland in Home Manager (if available).";
#     };
#   };

#   config = lib.mkIf cfg.enable {
#     environment.systemPackages = [ pkgs.hyprland ];

#     home-manager.users = lib.mkIf (hmAvailable && cfg.enableHomeManagerConfig && username != null) {
#       ${username} = { pkgs, ... }: {
#         wayland.windowManager.hyprland = {
#           enable = true;
#           extraConfig = ''
#             # This file can contain things you want at the top
#             # or just rely on sourced configs
#             source = ~/.config/hypr/monitors.conf
#             source = ~/.config/hypr/keybinds.conf
#             source = ~/.config/hypr/settings.conf
#           '';
#         };

#         # Install your Hyprland config fragments
#         home.file = {
#           ".config/hypr/monitors.conf".source = "${hyprDir}/monitors.conf";
#           ".config/hypr/keybinds.conf".source = "${hyprDir}/keybinds.conf";
#           ".config/hypr/settings.conf".source = "${hyprDir}/settings.conf";
#         };
#       };
#     };
#   };
# }
