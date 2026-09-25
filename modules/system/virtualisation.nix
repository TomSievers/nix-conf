{ pkgs, ... }:

{
  # Enable libvirtd for virtualisation and virt-manager GUI
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      vhostUserPackages = with pkgs; [ virtiofsd ];
      swtpm.enable = true;
    };
  };
  programs.virt-manager.enable = true;

  # Podman with a docker-compatible socket, so vscode dev containers work.
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };

  # Run binaries for other architectures through qemu-user.
  boot.binfmt.emulatedSystems = [
    "aarch64-linux"
    "armv7l-linux"
    "armv6l-linux"
  ];
  boot.binfmt.preferStaticEmulators = true;
}
