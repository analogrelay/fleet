import { Cli } from "clipanion";
import GenerateDhcpLeasesCommand from "./generate-dhcp";

const [node, app, ...args] = process.argv;

const cli = new Cli({
  binaryLabel: "Inventory tool",
  binaryName: "inventory",
  binaryVersion: "1.0.0",
})

cli.register(GenerateDhcpLeasesCommand);
cli.runExit(args);