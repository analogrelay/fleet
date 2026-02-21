{ config, lib, pkgs, ... }:

let
  cfg = config.fleet;
in
{
  config = lib.mkIf (cfg.role == "workstation") {
    fonts.fontDir.enable = true;
    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
  };
}
