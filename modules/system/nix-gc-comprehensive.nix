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

      usage() {
        echo "usage: nix-comprehensive-gc [GENERATIONS]"
        echo "Keep the last GENERATIONS generations (default ${toString cfg.keep}) of every"
        echo "Nix profile (system, users, home-manager), then garbage collect the store."
      }

      keep="''${1:-${toString cfg.keep}}"
      case "$keep" in
        -h|--help) usage; exit 0 ;;
      esac
      if ! [[ "$keep" =~ ^[1-9][0-9]*$ ]]; then
        usage >&2
        exit 1
      fi

      if [ "$(id -u)" -ne 0 ]; then
        echo "nix-comprehensive-gc must run as root (it trims every user's profiles)." >&2
        exit 1
      fi

      # 1. Trim generations of every profile to the last $keep. A profile is a
      #    symlink NAME next to its generation links NAME-<n>-link. This covers
      #    the system profile, root's profiles and each user's profiles (nix-env,
      #    `nix profile`, home-manager), in both the old and new locations.
      log "Keeping the last $keep generations of every profile"
      shopt -s nullglob
      for dir in \
        /nix/var/nix/profiles \
        /nix/var/nix/profiles/per-user/* \
        /root/.local/state/nix/profiles \
        /home/*/.local/state/nix/profiles; do
        [ -d "$dir" ] || continue
        for profile in "$dir"/*; do
          [ -L "$profile" ] || continue
          name="$(basename "$profile")"
          # Skip generation links themselves and links without generations (e.g. `default`).
          [[ "$name" =~ -[0-9]+-link$ ]] && continue
          generations=("$profile"-*-link)
          [ "''${#generations[@]}" -gt 0 ] || continue
          log "  $profile"
          nix-env -p "$profile" --delete-generations "+$keep" || true
        done
      done

      # 2. Drop the removed system generations from the boot menu.
      log "Updating boot entries"
      /nix/var/nix/profiles/system/bin/switch-to-configuration boot

      # 3. Report stray GC roots (result symlinks, direnv, docker, etc.) without deleting them blindly
      ${optionalString cfg.strayRoots.report ''
        log "Stray GC roots outside of managed profiles (review manually):"
        nix-store --gc --print-roots \
          | grep -v '^/proc' \
          | grep -v '/nix/var/nix/profiles' \
          | grep -v '/\.local/state/nix/profiles' \
          | grep -v '{censored}' || true
      ''}

      # 4. Delete everything no longer reachable from a remaining generation or GC root.
      log "Collecting garbage"
      nix-store --gc

      # 5. Optimise store (hardlink duplicate files across derivations)
      ${optionalString cfg.optimiseStore ''
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

    keep = mkOption {
      type = types.ints.positive;
      default = 5;
      description = ''
        Default number of most recent generations to keep for every profile
        (system, users, home-manager). Can be overridden per run:
        `nix-comprehensive-gc <n>`.
      '';
    };

    strayRoots.report = boolOpt true
      "Print GC roots outside managed profiles (e.g. stray ./result symlinks) for manual review.";

    optimiseStore = boolOpt true "Run `nix-store --optimise` after collection.";

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
