# Add this to your NixOS configuration (e.g. import it, or paste into configuration.nix)
{ config, pkgs, lib, ... }:

let
  bleBatteryCheck = pkgs.writeShellApplication {
    name = "ble-battery-check";
    runtimeInputs = [ pkgs.upower pkgs.libnotify pkgs.gawk pkgs.gnugrep pkgs.coreutils ];
    text = ''
      # Low-battery threshold (percent). Notification re-arms once the
      # device is seen above THRESHOLD + HYSTERESIS again.
      THRESHOLD=20
      HYSTERESIS=5

      STATE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/ble-battery-check"
      mkdir -p "$STATE_DIR"

      # Any upower device whose native object name starts with mouse_dev_
      # or keyboard_dev_ is a plain BLE HID peripheral (BlueZ Battery1
      # interface) whose warning-level/state upower never computes -
      # see /org/freedesktop/UPower/devices/{mouse,keyboard}_dev_<MAC>.
      mapfile -t DEVICES < <(upower -e | grep -E '/(mouse|keyboard)_dev_[0-9A-Fa-f_]+$')

      for dev in "''${DEVICES[@]}"; do
        info=$(upower -i "$dev")

        pct=$(awk -F': *' '/^[[:space:]]*percentage:/{gsub("%","",$2); print $2}' <<< "$info")
        model=$(awk -F': *' '/^[[:space:]]*model:/{print $2}' <<< "$info")
        [ -z "$model" ] && model=$(basename "$dev")

        # Skip devices that reported no percentage this cycle.
        [ -z "$pct" ] && continue

        state_file="$STATE_DIR/$(basename "$dev")"
        was_notified=0
        [ -f "$state_file" ] && was_notified=1

        if [ "$pct" -lt "$THRESHOLD" ]; then
          if [ "$was_notified" -eq 0 ]; then
            notify-send -u critical -a "Battery" "Low battery: $model" "''${pct}%"
            touch "$state_file"
          fi
        elif [ "$pct" -ge "$((THRESHOLD + HYSTERESIS))" ]; then
          rm -f "$state_file"
        fi
      done
    '';
  };
in
{
  systemd.user.services.ble-battery-check = {
    description = "Notify on low battery for BLE mice/keyboards";
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = "${bleBatteryCheck}/bin/ble-battery-check";
  };

  systemd.user.timers.ble-battery-check = {
    description = "Periodically check BLE peripheral battery levels";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5m";
      OnUnitActiveSec = "15m";
    };
  };
}
