{ config, lib, ... }:

let
  cfg = config.fleet;
in
{
  config = lib.mkIf (cfg.realm == "microsoft") { };
}
