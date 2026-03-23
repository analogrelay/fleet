{ ... }:

{
  security.pam.services.sudo_local = {
		enable = true;
		touchIdAuth = true;
		reattach = true;
	};

  nix = {
    linux-builder = {
      enable = true;
      config = { virtualisation.darwin-builder.memorySize = 8192; };
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 0;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };
  };
}
