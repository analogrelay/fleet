{ lib, ... }:

{
  programs.git.settings."gpg \"ssh\"".program = lib.mkForce { };
}
