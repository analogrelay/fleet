{ config, lib, pkgs, inputs, ... }:

{
  import = [
    ./_base.nix
  ]

  services.k3s = {
    role = "server";
    extraFlags = toString [
      "--disable=local-storage"
    ];
  };
}
