{ ... }:

{
	users.groups."oauth2-proxy" = {};
	users.users."oauth2-proxy" = {
		name = "oauth2-proxy";
		group = "oauth2-proxy";
		isSystemUser = true;
	};
}
