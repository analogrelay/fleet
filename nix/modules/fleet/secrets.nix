{ config, lib, pkgs, options, ... }:

let
  cfg = config.fleet;
  enabledSecrets = lib.filterAttrs (_: s: s.source != null || s.template != null) cfg.secrets;
  hasSecrets = enabledSecrets != { };
  requiredSecrets = lib.filterAttrs (_: s: s.required) enabledSecrets;
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
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "1Password secret URI (e.g. op://Vault/Item/Field). Mutually exclusive with template.";
      };

      template = lib.mkOption {
        type = lib.types.nullOr lib.types.lines;
        default = null;
        description = ''
          Template string with 1Password references (e.g. {{ op://Vault/Item/Field }}).
          Provisioned using `op inject`. Mutually exclusive with source.
        '';
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
        description = "Whether this secret is required. Failures for required secrets are logged as errors; optional secrets log warnings.";
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
        let
          isTemplate = secret.template != null;
          # Template secrets use `op inject -i <file>`; source secrets use `op read`.
          # The template file is safe in the Nix store — it only contains {{ op://… }}
          # placeholders, not actual secrets. Resolution happens at runtime.
          opCommand =
            if isTemplate then
              let templateFile = pkgs.writeText "${name}-template" secret.template;
              in "${lib.getExe pkgs._1password-cli} inject -i ${templateFile}"
            else
              "${lib.getExe pkgs._1password-cli} read \"${secret.source}\"";
        in
        if secret.required then ''
          echo "fleet-secrets: provisioning ${name} (required)" >&2
          OP_STDERR="$(mktemp)"
          if ! ${opCommand} > "$SECRETS_DIR/${name}" 2>"$OP_STDERR"; then
            echo "fleet-secrets: ERROR: failed to provision required secret ${name}" >&2
            cat "$OP_STDERR" >&2
            rm -f "$SECRETS_DIR/${name}" "$OP_STDERR"
            FAILED_REQUIRED="$FAILED_REQUIRED ${name}"
          else
            rm -f "$OP_STDERR"
            chmod ${secret.mode} "$SECRETS_DIR/${name}"
            chown ${secret.owner}:${secret.group} "$SECRETS_DIR/${name}"
          fi
        ''
        else ''
          echo "fleet-secrets: provisioning ${name} (optional)" >&2
          OP_STDERR="$(mktemp)"
          if ! ${opCommand} > "$SECRETS_DIR/${name}" 2>"$OP_STDERR"; then
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
      FAILED_REQUIRED=""

      export OP_CONFIG_DIR
      OP_CONFIG_DIR="$(mktemp -d)"
      trap 'rm -rf "$OP_CONFIG_DIR"' EXIT

      ${tokenLoader}

      # Purge and recreate the secrets directory
      rm -rf "$SECRETS_DIR"
      mkdir -p "$SECRETS_DIR"
      chmod 0751 "$SECRETS_DIR"

      if ! $HAS_TOKEN; then
        ${if hasRequired then ''
          echo "fleet-secrets: ERROR: required secrets exist but no token available" >&2
          FAILED_REQUIRED="${lib.concatStringsSep " " (lib.attrNames requiredSecrets)}"
        '' else ''
          echo "fleet-secrets: no token available but all secrets are optional, skipping" >&2
        ''}
      else
        export OP_SERVICE_ACCOUNT_TOKEN

        ${lib.concatStringsSep "\n" (lib.mapAttrsToList provisionSecret enabledSecrets)}
      fi

      if [ -n "$FAILED_REQUIRED" ]; then
        echo "fleet-secrets: ERROR: failed to provision required secrets:$FAILED_REQUIRED" >&2
        echo "fleet-secrets: services depending on these secrets may not work correctly" >&2
      else
        echo "fleet-secrets: all secrets provisioned" >&2
      fi
    '';
in
{
  options.fleet.secrets = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule secretOpts);
    default = { };
    description = "Declarative secrets provisioned from 1Password at boot.";
  };

  config = lib.mkIf hasSecrets (lib.mkMerge ([
    {
      assertions = lib.mapAttrsToList (name: secret: {
        assertion = (secret.source != null) != (secret.template != null);
        message = "fleet.secrets.\"${name}\": exactly one of 'source' or 'template' must be set, not both or neither.";
      }) enabledSecrets;
    }
  ]
    # NixOS: systemd service
    ++ lib.optional (!isDarwin) {
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
