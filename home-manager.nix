{
  config,
  lib,
  pkgs,
  inputs,
  system,
  ...
}:

with lib;

let
  cfg = config.user;
in
{
  options.user = {
    enable = mkEnableOption "Enable default software development user.";

    username = mkOption {
      type = types.str;
      default = null;
      description = ''
        Set the username for the system user 
      '';
    };

    description = mkOption {
      type = types.str;
      default = null;
      description = ''
        Set the user description for the system user.
      '';
    };

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [
        "networkmanager"
        "wheel"
        "dialout"
        "podman"
        "libvirtd"
        "plugdev"
        "uucp"
        "wireshark"
      ];
      description = "Extra groups to add the user to.";
    };

    homeConfig = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra home-manager configuration for this user.";
    };

    zshTheme = mkOption {
      type = types.str;
      default = "amuse";
      description = "Which zsh theme to use, defaults to amuse.";
    };
  };

  config = mkIf cfg.enable {

    home-manager.extraSpecialArgs = {
      inherit inputs;
    };

    users.users.${cfg.username} = {
      isNormalUser = true;
      extraGroups = cfg.extraGroups;
      shell = pkgs.zsh;
      createHome = true;
      description = cfg.description;
    };

    # We also need to enable zsh here because it is needed for the users config above.
    programs.zsh.enable = true;

    # Make docker socket (via podman) available for vscode.
    virtualisation.podman.dockerSocket.enable = true;
    virtualisation.podman.enable = true;
    virtualisation.podman.dockerCompat = true;

    # Hook in the Home Manager config for this user
    home-manager.users.${cfg.username} =
      { pkgs, inputs, ... }:
      {
        imports = [
          inputs.open-bamboo-networking.homeManagerModules.default
        ];
        config = mkMerge [
          {
            services.podman.enable = true;
            programs.vim.enable = true;

            # We also need to set this in home manager, otherwise we won't be able to install vscode.
            nixpkgs.config.allowUnfree = true;

            # Hint for using wayland instead of X
            home.sessionVariables.NIXOS_OZONE_WL = "1";

            # Copy wallpaper to user location
            home.file."/home/${cfg.username}/wallpapers/bg.jpg".source = ./wallpapers/wallpaper.jpg;

            # Set the wallpaper for gnome
            dconf.settings = {
              "org/gnome/desktop/background" = {
                picture-uri-dark = "file:///home/${cfg.username}/wallpapers/bg.jpg";
              };
            };

            programs.firefox = {
              enable = true;
              policies = {
                BlockAboutConfig = false;
                DefaultDownloadDirectory = "\${home}/Downloads";
                ExtensionSettings = {
                  "uBlock0@raymondhill.net" = {
                    default_area = "menupanel";
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                    installation_mode = "force_installed";
                    private_browsing = true;
                  };
                };
              };
            };

            home.packages = with pkgs; [
              # For docker/podman compose files.
              podman-compose

              # GUI applications
              rpi-imager
              sourcegit
              gparted
              orca-slicer
              freecad-wayland
              kicad
              vlc
              gimp

              # Nerd font for zsh
              nerd-fonts.adwaita-mono

            ];

            # Some sane default zsh configuration with some usefull aliases
            programs.zsh = {
              enable = true;
              enableCompletion = true;
              autosuggestion.enable = true;

              shellAliases = {
                ll = "ls -l";
                update = "sudo nixos-rebuild switch";
                system-upgrade = "sudo nix-channel --update && sudo nixos-rebuild switch --upgrade";
                system-clean = "sudo nix-env --delete-generations 14d && sudo nix-store --gc && sudo nix-collect-garbage -d";
              };

              history = {
                size = 2000;
                saveNoDups = true;
              };

              oh-my-zsh = {
                enable = true;
                plugins = [ "git" ];
                theme = cfg.zshTheme;
              };
            };

            # Configure git how I like it.
            programs.git = {
              enable = true;
              package = pkgs.gitFull;
              lfs.enable = true;
              settings = {
                user = {
                  name = "Tom Sievers";
                  email = "t.sievers@hanskamp.com";
                };
                # When pulling do a merge instead of fast forward or rebase.
                pull.rebase = "false";
                # Set default branch name to master
                init.defaultBranch = "master";
                # Make sure that crlf is properly converted.
                core.autocrlf = "input";
                # Setup the credential helper to store in the gnome keyring.
                credential.helper = "libsecret";
              };
            };

            # Setup vscode with some basic extensions to allow most development to occur in dev containers.
            programs.vscode = {
              enable = true;
              profiles.default = {
                enableExtensionUpdateCheck = true;
                enableUpdateCheck = true;
                userSettings = {
                  "editor.formatOnSave" = true;
                  "terminal.integrated.defaultProfile.linux" = "zsh";
                  "git.confirmSync" = false;
                  "dev.containers.dockerComposePath" = "podman-compose";
                  "dev.containers.dockerPath" = "podman";
                  "git.suggestSmartCommit" = false;
                  "docker.extension.enableComposeLanguageServer" = false;
                  "zig.zls.enabled" = "on";
                  "explorer.confirmDragAndDrop" = false;
                };
                extensions = with pkgs.vscode-extensions; [
                  ms-python.python
                  github.copilot
                  jnoortheen.nix-ide
                  docker.docker
                  ms-azuretools.vscode-containers
                  ms-vscode-remote.remote-containers
                  mhutchie.git-graph
                ];
              };
            };

            programs.open-bamboo-networking = {
              enable = true;
              target = "orca-slicer";
              pluginVersion = "02.03.00.99";
              package = inputs.open-bamboo-networking.packages.${system}.default;
            };

            home.stateVersion = "26.05"; # or your system version
          }
          cfg.homeConfig
        ];
      };
  };
}
