{ config, lib, pkgs, ... }:

with lib;

let
  home-manager = builtins.fetchTarball https://github.com/nix-community/home-manager/archive/release-25.05.tar.gz;
  cfg = config.user;
in
{
  imports = [
    (import "${home-manager}/nixos")
  ];

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
      default = [ "networkmanager" "wheel" "dialout" ];
      description = "Extra groups to add the user to.";
    };

    homeConfig = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra home-manager configuration for this user.";
    };

    zshTheme = mkOption {
      type = type.str;
      default = "amuse";
      description = "Which zsh theme to use, defaults to amuse.";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.username} = {
      isNormalUser = true;
      extraGroups = cfg.extraGroups;
      shell = pkgs.zsh;
      createHome = true;
      description = cfg.description;
    };

    # We also need to enable zsh here because it is needed for the users config above. 
    programs.zsh.enable = true;

    # Hook in the Home Manager config for this user
    home-manager.users.${cfg.username} = { pkgs, ... }: mkMerge [
      {
        services.podman.enable = true;
        programs.vim.enable = true;

        # We also need to set this in home manager, otherwise we won't be able to install vscode.
        nixpkgs.config.allowUnfree = true;

        # Hint for using wayland instead of X
        home.sessionVariables.NIXOS_OZONE_WL = "1";

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
          wineWowPackages.waylandFull

        ];

        # Some sane default zsh configuration with some usefull aliases
        programs.zsh = {
          enable = true;
          enableCompletion = true;
          autosuggestion.enable = true;

          shellAliases = {
            ll = "ls -l";
            update = "sudo nixos-rebuild switch";
            system-upgrade = "sudo nixos-rebuild switch --upgrade";
          };

          history = {
            size = 2000;
            saveNoDups = true;
          };

          oh-my-zsh = {
            enable = true;
            plugins = [ "git" ];
            theme = ${cfg.zshTheme};
          };
        };

        # Configure git how I like it.
        programs.git = {
          enable = true;
          package = pkgs.gitFull;
          lfs.enable = true;
          extraConfig = {
            user = {
              name = "Tom Sievers";
              email = "t.sievers@hanskamp.com";
            };

            init.defaultBranch = "master";

            core.autocrlf = "input";
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
            };
            extensions = with pkgs.vscode-extensions; [
              ms-python.python
              github.copilot
              ms-vscode-remote.vscode-remote-extensionpack
              jnoortheen.nix-ide
            ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
              {
                name = "docker";
                publisher = "docker";
                version = "0.18.0";
                sha256 = "a5XlZL7jExYPhz1HODCgvw29JTf7DNyUBFQWYe+4dmA=";
              }
              {
                name = "vscode-containers";
                publisher = "ms-azuretools";
                version = "2.2.0";
                sha256 = "UxWsu7AU28plnT0QMdpPJrcYZIV09FeC+rmYKf39a6M=";
              }
              {
                name = "git-graph";
                publisher = "mhutchie";
                version = "1.30.0";
                sha256 = "sHeaMMr5hmQ0kAFZxxMiRk6f0mfjkg2XMnA4Gf+DHwA=";
              }
            ];
          };
        };

        home.stateVersion = "25.05"; # or your system version
      }
      cfg.homeConfig
    ];
  };
}
