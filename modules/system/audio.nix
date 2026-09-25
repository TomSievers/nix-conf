{ config, pkgs, ... }:

{
  # Enable rtkit needed for pipewire and pulseaudio 
  security.rtkit.enable = true;
  # Configure pipewire to emulate all other services.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  }; 
}
