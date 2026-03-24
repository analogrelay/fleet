{ config, lib, tags, ... }:

let
  fleetSyncScript = "${config.fleet.repoDir}/script/fleet-sync";
  stateDir = "${config.home.homeDirectory}/.local/state/fleet";
in

{
  # Linux: systemd user service + nightly timer
  systemd.user.services = lib.mkIf (tags.os == "linux") {
    fleet-sync = {
      Unit = {
        Description = "fleet nightly sync and pre-build";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = fleetSyncScript;
        Environment = [
          "HOME=%h"
          "PATH=/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:%h/.nix-profile/bin"
        ];
      };
    };
  };

  systemd.user.timers = lib.mkIf (tags.os == "linux") {
    fleet-sync = {
      Unit.Description = "fleet nightly sync timer";
      Timer = {
        OnCalendar = "02:00:00";
        # Run once to catch up if the machine was off at 2am — systemd fires
        # the service exactly once regardless of how many ticks were missed.
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };

  # macOS: launchd user agent with nightly calendar trigger
  launchd.agents = lib.mkIf (tags.os == "darwin") {
    fleet-sync = {
      enable = true;
      config = {
        Label = "net.analogrelay.fleet-sync";
        ProgramArguments = [ fleetSyncScript ];
        StartCalendarInterval = [ { Hour = 2; Minute = 0; } ];
        StandardOutPath = "${stateDir}/fleet-sync.log";
        StandardErrorPath = "${stateDir}/fleet-sync.log";
        RunAtLoad = false;
      };
    };
  };
}
