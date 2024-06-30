import { Command, Option } from "clipanion";
import { loadInventory } from "../lib";
import { open } from "node:fs/promises";
import { WriteStream } from "node:fs";

export default class GenerateDhcpLeasesCommand extends Command {
  static paths = [[`generate`, `dhcp-leases`]];

  inventoryPath = Option.String("--inventory", { description: "The path to the inventory file.", required: false });
  outputPath = Option.String("--output", { description: "The path to a file to write the output to. If omitted, or '-', writes to stdout.", required: false });

  async execute(): Promise<number | void> {
    const inventory = await loadInventory(this.inventoryPath);

    let writeLine: (line:string) => void = console.log;
    if (this.outputPath && this.outputPath !== "-") {
      const file = await open(this.outputPath, "w+");
      const stream = file.createWriteStream({ encoding: "utf-8" });
      writeLine = line => stream.write(`${line}\n`);
    }

    for(const network of inventory.networks.values()) {
      if(!network.dhcpServer) {
        continue;
      }
      for(const connection of network.connections) {
        const primaryMac = connection.node.macAddresses[0];
        if (!primaryMac) {
          continue;
        }
        const primaryIp = connection.ipv4Addresses[0];
        if (!primaryIp) {
          continue;
        }
        writeLine(`/ip/dhcp-server/lease remove [find where mac-address=${primaryMac} server=${network.dhcpServer}]`)
        writeLine(`/ip/dhcp-server/lease add mac-address=${primaryMac} address=${primaryIp} comment=${connection.fqdn} server=${network.dhcpServer}`);
      }
    }
  }
}