# Fleet module tests.
# Returns an attrset of derivations suitable for use as flake checks.
#
# Usage in flake.nix:
#   checks.x86_64-linux = import ./nix/modules/fleet/tests {
#     inherit pkgs lib;
#   };
{ pkgs, lib }:

let
  # Evaluate the fleet module against a minimal NixOS system.
  evalFleet =
    modules:
    import (pkgs.path + "/nixos/lib/eval-config.nix") {
      inherit lib;
      system = "x86_64-linux";
      modules = [
        ../default.nix
        # Minimal user stub required because fleet.root derives from adminHome.
        {
          users.users.testadmin = {
            isNormalUser = true;
            home = "/home/testadmin";
          };
          fleet.admin = "testadmin";
          fleet.platform = "nixos";
          fleet.role = "server";
        }
      ] ++ modules;
      specialArgs = {
        inherit pkgs;
        tags = { };
      };
    };

  # ---- pure-evaluation assertion helpers --------------------------------

  # Assert that `expr` is true; produce a derivation that fails otherwise.
  assertTrue =
    name: expr:
    pkgs.runCommand name { } (
      if expr then "touch $out" else ''
        echo "FAIL: assertion '${name}' is false"
        exit 1
      ''
    );

  # Assert that two values are equal.
  assertEqual =
    name: a: b:
    assertTrue name (a == b);

in
{
  # ---------------------------------------------------------------------------
  # 1. fleet.identity defaults to networking.hostName when not explicitly set.
  # ---------------------------------------------------------------------------
  fleet-identity-default =
    let
      evaled = evalFleet [ { networking.hostName = "mybox"; } ];
    in
    assertEqual "fleet-identity-default" evaled.config.fleet.identity "mybox";

  # ---------------------------------------------------------------------------
  # 2. fleet.identity can be overridden and is written to /etc/fleet/identity.
  # ---------------------------------------------------------------------------
  fleet-identity-file =
    let
      evaled = evalFleet [ { fleet.identity = "testhost"; } ];
    in
    assertEqual "fleet-identity-file"
      evaled.config.environment.etc."fleet/identity".text
      "testhost\n";

  # ---------------------------------------------------------------------------
  # 3. fleet.secrets accepts a plain op:// string and resolves .path correctly.
  # ---------------------------------------------------------------------------
  fleet-secret-string-coercion =
    let
      evaled = evalFleet [
        {
          fleet.secrets.my-key = "op://Vault/Item/field";
        }
      ];
    in
    assertEqual "fleet-secret-string-coercion"
      evaled.config.fleet.secrets.my-key.path
      "/run/secrets/1p/my-key";

  # ---------------------------------------------------------------------------
  # 4. fleet.secrets accepts a full attrset form and preserves .path.
  # ---------------------------------------------------------------------------
  fleet-secret-attrset-form =
    let
      evaled = evalFleet [
        {
          fleet.secrets.db-pass = {
            ref = "op://Vault/DB/password";
            owner = "postgres";
            group = "postgres";
            mode = "0440";
          };
        }
      ];
    in
    assertEqual "fleet-secret-attrset-form"
      evaled.config.fleet.secrets.db-pass.path
      "/run/secrets/1p/db-pass";

  # ---------------------------------------------------------------------------
  # 5. provision-1p-secrets service is activated when secrets are defined.
  # ---------------------------------------------------------------------------
  fleet-secrets-service-enabled =
    let
      evaled = evalFleet [
        {
          fleet.secrets.my-key = "op://Vault/Item/field";
        }
      ];
    in
    assertTrue "fleet-secrets-service-enabled" (
      builtins.elem "multi-user.target"
        evaled.config.systemd.services.provision-1p-secrets.wantedBy
    );

  # ---------------------------------------------------------------------------
  # 6. provision-1p-secrets service is NOT activated when no secrets defined.
  # ---------------------------------------------------------------------------
  fleet-secrets-service-disabled =
    let
      evaled = evalFleet [ { fleet.secrets = { }; } ];
    in
    assertTrue "fleet-secrets-service-disabled" (
      !(evaled.config.systemd.services ? provision-1p-secrets)
      || evaled.config.systemd.services.provision-1p-secrets.wantedBy == [ ]
    );

  # ---------------------------------------------------------------------------
  # 7. fleet.link returns a path under fleet.root.
  # ---------------------------------------------------------------------------
  fleet-link-path =
    let
      evaled = evalFleet [ { fleet.identity = "testhost"; } ];
      linked = evaled.config.fleet.link "config/foo";
      expected = "${evaled.config.fleet.root}/config/foo";
    in
    assertEqual "fleet-link-path" linked expected;

  # ---------------------------------------------------------------------------
  # 8. FLEET_* environment variables are exported.
  # ---------------------------------------------------------------------------
  fleet-env-vars =
    let
      evaled = evalFleet [ { fleet.identity = "envtest"; } ];
      vars = evaled.config.environment.variables;
    in
    assertTrue "fleet-env-vars" (
      vars.FLEET_IDENTITY == "envtest"
      && vars.FLEET_ADMIN == "testadmin"
      && vars.FLEET_ROOT == "/home/testadmin/.config/fleet"
    );

  # ---------------------------------------------------------------------------
  # 9. VM test: /etc/fleet/identity file is present on a running system.
  # ---------------------------------------------------------------------------
  fleet-identity-vm = pkgs.nixosTest {
    name = "fleet-identity-vm";
    nodes.machine =
      { ... }:
      {
        imports = [ ../default.nix ];
        users.users.testadmin = {
          isNormalUser = true;
          home = "/home/testadmin";
        };
        fleet.admin = "testadmin";
        fleet.platform = "nixos";
        fleet.role = "server";
        fleet.identity = "vmhost";
      };
    testScript = ''
      machine.wait_for_unit("multi-user.target")
      identity = machine.succeed("cat /etc/fleet/identity").strip()
      assert identity == "vmhost", f"Expected 'vmhost', got '{identity!r}'"
      print("PASS: /etc/fleet/identity contains 'vmhost'")
    '';
  };
}
