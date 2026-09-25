{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nix-gc-comprehensive;

  cleanupScript = pkgs.writeShellApplication {
    name = "nix-comprehensive-gc";
    runtimeInputs = with pkgs; [ nix coreutils gnugrep ];
    text = ''
      set -euo pipefail
      log() { echo "[nix-gc] $*"; }

      # 1. Trim NixOS system generations (this is what your bootloader list draws from)
      ${optionalString cfg.systemGenerations.enable ''
        log "Trimming system profile to last ${toString cfg.systemGenerations.keep} generations"
        nix-env -p /nix/var/nix/profiles/system --delete-generations +${toString cfg.systemGenerations.keep}
      ''}

      # 2. Trim per-user nix-env / nix profile generations
      ${optionalString cfg.userGenerations.enable ''
        log "Trimming per-user profiles (keeping last ${toString cfg.userGenerations.keep})"
        for profile in /nix/var/nix/profiles/per-user/*/profile; do
          [ -e "$profile" ] || continue
          user="$(basename "$(dirname "$profile")")"
          log "  user: $user"
          nix-env -p "$profile" --delete-generations +${toString cfg.userGenerations.keep} || true
        done
      ''}

      # 3. home-manager generations
      ${optionalString cfg.homeManager.enable ''
        if command -v home-manager >/dev/null 2>&1; then
          log "Expiring home-manager generations older than ${cfg.homeManager.olderThan}"
          home-manager expire-generations "${cfg.homeManager.olderThan}" || true
        fi
      ''}

      # 4. Flake-style `nix profile` history
      ${optionalString cfg.profileWipeHistory.enable ''
        log "Wiping nix profile history older than ${cfg.profileWipeHistory.olderThan}"
        nix profile wipe-history --older-than ${cfg.profileWipeHistory.olderThan} || true
      ''}

      # 5. Report stray GC roots (result symlinks, direnv, docker, etc.) without deleting them blindly
      ${optionalString cfg.strayRoots.report ''
        log "Stray GC roots outside of managed profiles (review manually):"
        nix-store --gc --print-roots \
          | grep -v '^/proc' \
          | grep -v '/nix/var/nix/profiles' \
          | grep -v '{censored}' || true
      ''}

      # 6. System-wide GC
      log "Running system garbage collection (older than ${cfg.gc.systemOlderThan})"
      nix-collect-garbage --delete-older-than ${cfg.gc.systemOlderThan}

      # 7. Per-user GC (in case a user's own store roots differ from root's view)
      ${optionalString cfg.gc.perUser ''
        for profile in /nix/var/nix/profiles/per-user/*; do
          [ -d "$profile" ] || continue
          user="$(basename "$profile")"
          log "Running user garbage collection for: $user"
          su - "$user" -c "nix-collect-garbage --delete-older-than ${cfg.gc.userOlderThan}" || true
        done
      ''}

      # 8. Optimise store (hardlink duplicate files across derivations)
      ${optionalString cfg.gc.optimiseStore ''
        log "Optimising store (deduplicating identical files)"
        nix-store --optimise
      ''}

      log "Done."
    '';
  };

  boolOpt = default: description: mkOption { type = types.bool; inherit default description; };
in
{
  options.services.nix-gc-comprehensive = {
    enable = mkEnableOption "comprehensive Nix garbage collection";

    systemGenerations = {
      enable = boolOpt true "Trim /nix/var/nix/profiles/system (NixOS boot generations).";
      keep = mkOption {
        type = types.int;
        default = 5;
        description = "Number of most recent system generations to keep.";
      };
    };

    userGenerations = {
      enable = boolOpt true "Trim per-user nix-env/nix profile generations.";
      keep = mkOption {
        type = types.int;
        default = 5;
        description = "Number of most recent per-user generations to keep.";
      };
    };

    homeManager = {
      enable = boolOpt true "Expire home-manager generations, if home-manager is installed.";
      olderThan = mkOption {
        type = types.str;
        default = "-14 days";
        description = "Passed to `home-manager expire-generations`.";
      };
    };

    profileWipeHistory = {
      enable = boolOpt true "Wipe `nix profile` (flake-style) history.";
      olderThan = mkOption {
        type = types.str;
        default = "14d";
        description = "Passed to `nix profile wipe-history --older-than`.";
      };
    };

    strayRoots.report = boolOpt true
      "Print GC roots outside managed profiles (e.g. stray ./result symlinks) for manual review.";

    gc = {
      systemOlderThan = mkOption {
        type = types.str;
        default = "14d";
        description = "Passed to the root `nix-collect-garbage --delete-older-than`.";
      };
      perUser = boolOpt true "Also run nix-collect-garbage as each user (catches user-owned roots).";
      userOlderThan = mkOption {
        type = types.str;
        default = "14d";
        description = "Passed to each user's `nix-collect-garbage --delete-older-than`.";
      };
      optimiseStore = boolOpt true "Run `nix-store --optimise` after collection.";
    };

    automatic = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable a systemd timer to run this automatically. If false, only the
        `nix-comprehensive-gc` command is installed for manual/cron use.
      '';
    };

    schedule = mkOption {
      type = types.str;
      default = "weekly";
      description = "systemd OnCalendar spec, used only when `automatic = true`.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cleanupScript ];

    systemd.services.nix-comprehensive-gc = {
      description = "Comprehensive Nix store garbage collection";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cleanupScript}/bin/nix-comprehensive-gc";
      };
    };

    systemd.timers.nix-comprehensive-gc = mkIf cfg.automatic {
      description = "Timer for comprehensive Nix garbage collection";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.schedule;
        Persistent = true;
      };
    };
  };
}
