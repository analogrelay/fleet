{ tags, config, ... }:

let
  fleetLink = path:
    config.lib.file.mkOutOfStoreSymlink "${config.fleet.repoDir}/${path}";
in {
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        email = if (tags.realm == "microsoft") then "ashleyst@microsoft.com" else "contact@analogrelay.dev";
        name = "Ashley Stanton-Nurse";
      };
      git.sign-on-push = true;
      signing = {
        behavior = "drop";
        backend = "ssh";
        key = fleetLink "keys/gitSigning.pub";
        backends.ssh.program = if (tags.wsl)
          then (if (tags.realm == "microsoft") 
            then "/mnt/c/Users/ashleyst/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe"
            else "/mnt/c/Users/ashley/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe")
          else "op-ssh-sign";
      };
    };
  };
}
