{ config, lib, pkgs, options, ... }:

let
  cfg = config.fleet;
  enabledSecrets = lib.filterAttrs (_: s: s.source != null) cfg.secrets;
  hasSecrets = enabledSecrets != { };
  requiredSecrets = lib.filterAttrs (_: s: s.required) enabledSecrets;
  optionalSecrets = lib.filterAttrs (_: s: !s.required) enabledSecrets;
  hasRequired = requiredSecrets != { };
  isDarwin = options ? launchd;
  secretsDir =
    if isDarwin
    then "/var/run/secrets/fleet"
    else "/run/secrets/fleet";
  defaultGroup = if isDarwin then "wheel" else "root";

  secretOpts = { name, ... }: {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        description = "1Password secret URI (e.g. op://Vault/Item/Field).";
      };

      path = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = "${secretsDir}/${name}";
        description = "Absolute path to the provisioned secret file.";
      };

      owner = lib.mkOption {
        type = lib.types.str;
        default = "root";
        description = "Owner of the secret file.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = defaultGroup;
        description = "Group of the secret file.";
      };

      mode = lib.mkOption {
        type = lib.types.str;
        default = "0400";
        description = "File permissions for the secret file.";
      };

      required = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether provisioning failure for this secret should fail the service.";
      };
    };
  };

  provisionScript =
    let
      tokenLoader =
        if isDarwin
        then ''
          # Try macOS Keychain first, fall back to token file
          if /usr/bin/security find-generic-password -s "fleet" -a "1p-service-account" -w >/dev/null 2>&1; then
            OP_SERVICE_ACCOUNT_TOKEN="$(/usr/bin/security find-generic-password -s "fleet" -a "1p-service-account" -w)"
          elif [ -f "$TOKEN_FILE" ]; then
            OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"
          else
            echo "fleet-secrets: no token in Keychain (fleet/1p-service-account) or $TOKEN_FILE" >&2
            HAS_TOKEN=false
          fi
        ''
        else ''
          # Try systemd-creds encrypted credential, fall back to token file
          CRED_FILE="/etc/credstore.encrypted/fleet-1p-token"
          if [ -f "$CRED_FILE" ]; then
            OP_SERVICE_ACCOUNT_TOKEN="$(systemd-creds decrypt --name=fleet-1p-token "$CRED_FILE" -)"
          elif [ -f "$TOKEN_FILE" ]; then
            OP_SERVICE_ACCOUNT_TOKEN="$(cat "$TOKEN_FILE")"
          else
            echo "fleet-secrets: no token in $CRED_FILE or $TOKEN_FILE" >&2
            HAS_TOKEN=false
          fi
        '';

      provisionSecret = name: secret:
        if secret.required then ''
          echo "fleet-secrets: provisioning ${name} (required)" >&2
          OP_STDERR="$(mktemp)"
          if ! ${lib.getExe pkgs._1password-cli} read "${secret.source}" > "$SECRETS_DIR/${name}" 2>"$OP_STDERR"; then
            echo "fleet-secrets: ERROR: failed to provision required secret ${name}" >&2
            cat "$OP_STDERR" >&2
            rm -f "$SECRETS_DIR/${name}" "$OP_STDERR"
            exit 1
          fi
          rm -f "$OP_STDERR"
          chmod ${secret.mode} "$SECRETS_DIR/${name}"
          chown ${secret.owner}:${secret.group} "$SECRETS_DIR/${name}"
        ''
        else ''
          echo "fleet-secrets: provisioning ${name} (optional)" >&2
          OP_STDERR="$(mktemp)"
          if ! ${lib.getExe pkgs._1password-cli} read "${secret.source}" > "$SECRETS_DIR/${name}" 2>"$OP_STDERR"; then
            echo "fleet-secrets: WARNING: failed to provision optional secret ${name}, skipping" >&2
            cat "$OP_STDERR" >&2
            rm -f "$SECRETS_DIR/${name}" "$OP_STDERR"
          else
            rm -f "$OP_STDERR"
            chmod ${secret.mode} "$SECRETS_DIR/${name}"
            chown ${secret.owner}:${secret.group} "$SECRETS_DIR/${name}"
          fi
        '';
    in
    pkgs.writeShellScript "provision-fleet-secrets" ''
      set -euo pipefail

      TOKEN_FILE="/etc/fleet/1p-token"
      SECRETS_DIR="${secretsDir}"
      HAS_TOKEN=true

      export OP_CONFIG_DIR
      OP_CONFIG_DIR="$(mktemp -d)"
      trap 'rm -rf "$OP_CONFIG_DIR"' EXIT

      ${tokenLoader}

      if ! $HAS_TOKEN; then
        ${if hasRequired then ''
          echo "fleet-secrets: required secrets exist but no token available, failing" >&2
          exit 1
        '' else ''
          echo "fleet-secrets: no token available but all secrets are optional, skipping" >&2
          exit 0
        ''}
      fi
      export OP_SERVICE_ACCOUNT_TOKEN

      # Purge and recreate the secrets directory
      rm -rf "$SECRETS_DIR"
      mkdir -p "$SECRETS_DIR"
      chmod 0751 "$SECRETS_DIR"

      ${lib.concatStringsSep "\n" (lib.mapAttrsToList provisionSecret enabledSecrets)}

      echo "fleet-secrets: all secrets provisioned"
    '';
in
{
  options.fleet.secrets = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule secretOpts);
    default = { };
    description = "Declarative secrets provisioned from 1Password at boot.";
  };

  config = lib.mkIf hasSecrets (lib.mkMerge (
    # NixOS: systemd service
    lib.optional (!isDarwin) {
      systemd.services.provision-fleet-secrets = {
        description = "Provision fleet secrets from 1Password";
        wantedBy = [ "multi-user.target" ];
        before = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = provisionScript;
        };
      };
    }

    # Darwin: launchd daemon
    ++ lib.optional isDarwin {
      launchd.daemons.provision-fleet-secrets = {
        serviceConfig = {
          Label = "com.fleet.provision-secrets";
          ProgramArguments = [ "${provisionScript}" ];
          RunAtLoad = true;
        };
      };
    }
  ));
}
