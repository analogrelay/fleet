import * as azure from '@pulumi/azure-native';
import resourceGroup from './resourceGroup.js';
import { msftbenefit } from '../../global.js';

export const adminSshKey = new azure.compute.SshPublicKey("analogcompute/ssh/cloud-server-admin", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  sshPublicKeyName: "cloud-server-admin-key",
  publicKey: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDGCscIM2IOe+grCLObu6o9i4bdaY5O5PKIzlBI2GqVjOyLQkT8K8YpcQZE8XuYAOWuGAWTRDPRW5HJY8K7Yw0bLg9IeZvtwxUJSxe1rVfjCUeUVeMhKTmhoM2cvlCQwE7R23G3XWW+/1ORQ6qVLA1cW2AK1yt6+iG25I3EDi9M37Uh+hq/mmhHCJ2+nOBs/1Bsr/FCbLeZ7usV7leFeRJkDB2HaSrlnMNZuJrVvofJDDIJT6wAj/L9fQxGtXqLp49hRc7QllD9MyjGzVSqqvw1cOGneMLOxWQhQVfD96QG+OojpLjkH5TQ+VWEn+Sk8Ny95t/fM+CiTQy1O8efLJA6hq0+F4G1YkzYVkeAxzu6dfXDB+vV6CgYGn+f+ERDAz1rKq6fAm4SXzVA6j6LNF7URsWnKhKs/xDWmd5J7XHRzBg+1Ez6fFRwhVJ0iqKq69mFixbVsWYo2qF9lvNRQC2b7+//cVcdeHU4Riqivdh48mv52PVTUr4t3bsoEuw6wMmFaMcBTxQIIxT18hpjdBgS3u2ei5cu4W/GDGtJeIX1AbFGqYu8KijsuAnwaJw0m9Hu19mNXOxjtKNY1CphrGmaU9XFRssfFFj5y1LGbiqGez4ONnYXZOwMFTSbTogPuiALT9kKn9JHPYXxzP7tS1ELaS/79FSPCnXHVGb8Ve5P+w==",
});

export const k3sServerIdentity = new azure.managedidentity.UserAssignedIdentity("analogcompute/id/k3s-server", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  resourceName: "k3s-server",
}, { provider: msftbenefit });

export const k3sAgentIdentity = new azure.managedidentity.UserAssignedIdentity("analogcompute/id/k3s-agent", {
  resourceGroupName: resourceGroup.name,
  location: resourceGroup.location,
  resourceName: "k3s-agent",
}, { provider: msftbenefit });