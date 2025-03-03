{ pkgs, ... }:

{
  # Create fleet-wide groups and users, which all have consistent GIDs/UIDs which start with 5000
  users = {
    groups = {
      family = {
        gid = 5000;
      };
      parents = {
        gid = 5001;
      };
      kids = {
        gid = 5002;
      };
      share = {
        gid = 5003;
      };
    };

    users = {
      share = {
        uid = 5000;
        description = "Share User";
        shell = pkgs.zsh;
        isNormalUser = true;
        extraGroups = [
          "share"
        ];
      };
    };
  };
}
