{ pkgs, config, ... }:

{
	services.fail2ban = {
		enable = true;
	};

	environment.systemPackages = [
		pkgs.fail2ban
		pkgs.jq
	];

	# Action definition — adds/removes IPs from a Cloudflare account-level
	# Rules List via the v4 API. Jails reference this as action = cloudflare-list.
	environment.etc."fail2ban/action.d/cloudflare-list.conf".text =
		''
		# Fail2Ban action: add/remove IPs from a Cloudflare Rules List.
		# Requires: curl, jq
		#
		# The list is assumed to be referenced by a WAF custom rule that
		# blocks (or challenges) any source IP present in the list.

		[Definition]

		actionstart =

		actionstop =

		actioncheck =

		# Add the offending IP to the Cloudflare list.
		actionban = curl -s -o /dev/null -w "%%{http_code}" -X POST \
		              "<_cf_api_url>" \
		              <_cf_api_prms> \
		              --data '[{"ip":"<ip>","comment":"Fail2Ban <name>"}]'

		# Remove the IP from the Cloudflare list.
		# 1. Search for list items matching the IP.
		# 2. Extract the item ID for the exact IP match.
		# 3. Delete by item ID.
		actionunban = _item_id=$(curl -s -X GET \
		                "<_cf_api_url>?search=<ip>" \
		                <_cf_api_prms> \
		                | jq -r '.result[] | select(.ip == "<ip>") | .id' \
		                | head -n 1) && \
		              if [ -z "$_item_id" ]; then \
		                echo "<name>: list item for <ip> not found; skipping"; \
		                exit 0; \
		              fi && \
		              curl -s -o /dev/null -w "%%{http_code}" -X DELETE \
		                "<_cf_api_url>" \
		                <_cf_api_prms> \
		                --data "{\"items\":[{\"id\":\"$_item_id\"}]}"

		_cf_api_url = https://api.cloudflare.com/client/v4/accounts/<cfaccountid>/rules/lists/<cflistid>/items
		_cf_api_prms = -H "Authorization: Bearer <cftoken>" -H "Content-Type: application/json"

		[Init]

		# Override these in cloudflare-list.local (provisioned from 1Password).
		cftoken =
		cfaccountid =
		cflistid =
		'';

	# Secret overrides — credentials injected from 1Password at boot.
	fleet.secrets."cloudflare-fail2ban-list-action".template =
		''
		[Init]
		cftoken = {{ op://Fleet/Cloudflare/fail2ban-token }}
		cfaccountid = {{ op://Fleet/Cloudflare/account-id }}
		cflistid = {{ op://Fleet/Cloudflare/fail2ban-list-id }}
		'';

	# Symlink the provisioned secret into the fail2ban action.d directory
	# so fail2ban reads it as the .local override for cloudflare-list.
	systemd.tmpfiles.rules = [
		"L /etc/fail2ban/action.d/cloudflare-list.local - - - - ${config.fleet.secrets."cloudflare-fail2ban-list-action".path}"
	];

	# Ensure fail2ban starts after secrets have been provisioned.
	systemd.services.fail2ban = {
		after = [ "provision-fleet-secrets.service" ];
		wants = [ "provision-fleet-secrets.service" ];
	};
}
