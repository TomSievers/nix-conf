# Notify logged-in users when the flake inputs (e.g. nixpkgs 26.05) have new
# commits upstream, so `system-upgrade` has something to install. Only checks
# with `git ls-remote`; it never downloads sources or touches flake.lock.

{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.flake-update-check;

  checkScript = pkgs.writeShellApplication {
    name = "flake-update-check";
    runtimeInputs = with pkgs; [ coreutils git jq libnotify ];
    text = ''
      lock=${escapeShellArg "${config.nixConf.flakeDir}/flake.lock"}
      ignore=${escapeShellArg (concatStringsSep " " cfg.ignoreInputs)}
      state="''${XDG_RUNTIME_DIR:-/tmp}/flake-update-check"

      if [ ! -r "$lock" ]; then
        echo "Cannot read $lock" >&2
        exit 1
      fi

      updates=()
      checked=0
      failed=0
      latest_revs=""
      for input in $(jq -r '.nodes.root.inputs | keys[]' "$lock"); do
        [[ " $ignore " == *" $input "* ]] && continue

        node="$(jq -r --arg i "$input" '.nodes.root.inputs[$i]' "$lock")"
        info="$(jq -r --arg n "$node" '.nodes[$n] | [
            .original.type,
            (if .original.type == "github" then "https://github.com/\(.original.owner)/\(.original.repo)" else .original.url end),
            (.original.ref // "HEAD"),
            (.original.rev // ""),
            .locked.rev
          ] | join("|")' "$lock")"
        IFS="|" read -r type url ref pinned locked <<< "$info"

        # Inputs pinned to a revision, or of other types, cannot have updates.
        [ -z "$pinned" ] || continue
        [[ "$type" == github || "$type" == git ]] || continue

        if [ "$ref" = HEAD ]; then
          latest="$(git ls-remote "$url" HEAD | cut -f1 | head -n1)" || { failed=$((failed + 1)); continue; }
        else
          latest="$(git ls-remote "$url" "refs/heads/$ref" "refs/tags/$ref" | cut -f1 | head -n1)" || { failed=$((failed + 1)); continue; }
        fi
        if [ -z "$latest" ]; then
          echo "Could not resolve $input ($url $ref), skipping" >&2
          continue
        fi
        checked=$((checked + 1))

        if [ "$latest" != "$locked" ]; then
          updates+=("$input")
          latest_revs+="$input=$latest"$'\n'
        fi
      done

      if [ "''${#updates[@]}" -eq 0 ] && [ "$failed" -gt 0 ]; then
        # Probably offline (e.g. right after login): fail so systemd retries.
        echo "Could not reach $failed of $((checked + failed)) remotes, retrying later." >&2
        exit 1
      fi

      if [ "''${#updates[@]}" -eq 0 ]; then
        echo "Everything is up to date."
        rm -f "$state"
        exit 0
      fi

      echo "Updates available for: ''${updates[*]}"

      # Notify once per graphical login session: every desktop login gets a
      # new invocation ID for graphical-session.target, even if the user
      # manager (and $XDG_RUNTIME_DIR) survives because another session is open.
      session="$(systemctl --user show graphical-session.target -p InvocationID --value 2>/dev/null || true)"
      if [ -z "$session" ]; then
        echo "No graphical session, not notifying."
        exit 0
      fi
      # Within one session, only notify again when even newer revisions appear.
      key="session=$session"$'\n'"$latest_revs"
      if [ -f "$state" ] && [ "$(cat "$state")" = "$(printf '%s' "$key")" ]; then
        exit 0
      fi

      list="$(printf '%s, ' "''${updates[@]}")"
      notify-send \
        --app-name=NixOS \
        --icon=software-update-available \
        "System updates available" \
        "New versions of: ''${list%, }.
Run system-upgrade to install them."
      printf '%s' "$key" > "$state"
    '';
  };
in
{
  options.services.flake-update-check = {
    enable = mkEnableOption "desktop notifications when flake inputs have upstream updates";

    interval = mkOption {
      type = types.str;
      default = "4h";
      description = "How often to check after the first check at login (systemd time span).";
    };

    ignoreInputs = mkOption {
      type = types.listOf types.str;
      default = [ "nixpkgs-unstable" ];
      description = ''
        Flake inputs not to check. nixpkgs-unstable changes daily and is updated
        separately with `nix-bump-unstable`.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ checkScript ];

    systemd.user.services.flake-update-check = {
      description = "Check for NixOS flake input updates";
      # Also check at every desktop login, not only when the user manager starts.
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      # Retry while offline (the script fails when a remote could not be reached).
      unitConfig = {
        StartLimitIntervalSec = "1h";
        StartLimitBurst = 10;
      };
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "2min";
        ExecStart = "${checkScript}/bin/flake-update-check";
      };
    };

    systemd.user.timers.flake-update-check = {
      description = "Check for NixOS flake input updates at login and periodically";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        # After the user manager starts, then every interval (desktop logins
        # also trigger the service directly through graphical-session.target).
        OnStartupSec = "2min";
        OnUnitActiveSec = cfg.interval;
        RandomizedDelaySec = "5min";
      };
    };
  };
}
