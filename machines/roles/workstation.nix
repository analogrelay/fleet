{ pkgs, lib, platform, wsl, ... }:

{
  imports = [
  ] ++ (lib.optional (builtins.pathExists ./workstation.${platform}.nix) ./workstation.${platform}.nix);

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      monaspace
      (nerdfonts.override { fonts = [ "Monaspace" ]; })
    ];
  };

  home-manager.extraSpecialArgs = {
    role = "workstation";
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
    };
  };
}
