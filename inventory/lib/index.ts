export * from "./types.js";

import TOML from "smol-toml";
import { Connection, Inventory, Network, Node } from "./types.js";
import { writeFile, readFile } from "fs/promises";
import path from "path";

interface TomlInventory {
  network?: Record<string, TomlNetwork>,
  node?: Record<string, TomlNode>,
}

interface TomlNetwork {
  vlan?: number | undefined,
  dns?: boolean | undefined,
  dhcpServer?: string | undefined,
  name?: string | undefined,
  external?: boolean | undefined
  domain?: string | undefined,
  subdomain?: string | undefined,
  description?: string | undefined,
  config?: Record<string, unknown> | undefined,
}

interface TomlNode {
  /** The host name of the node */
  name?: string | undefined,
  description?: string | undefined,
  macAddresses?: string[] | undefined,
  connection?: Record<string, TomlConnection> | undefined,
  config?: Record<string, unknown> | undefined,
}

interface TomlConnection {
  hostname?: string,
  ipAddresses?: string[],
  config?: Record<string, unknown> | undefined,
}

export async function loadInventory(inputPath: string): Promise<Inventory> {
  const content = await readFile(inputPath, { encoding: "utf-8" });
  const tomlInventory = TOML.parse(content) as TomlInventory;

  let nodes = new Map<string, Node>();
  let networks = new Map<string, Network>();

  for (const [key, tomlNetwork] of Object.entries(tomlInventory.network ?? {})) {
    const network = new Network(
      key,
      tomlNetwork.name ?? key,
      tomlNetwork.dns ?? false,
      tomlNetwork.vlan ?? 0,
      !!tomlNetwork.external,
      tomlNetwork.subdomain ?? "",
      tomlNetwork.description ?? "",
      tomlNetwork.config || {},
      tomlNetwork.dhcpServer,
    );
    networks.set(key, network);
  }

  for (const [key, tomlNode] of Object.entries(tomlInventory.node ?? {})) {
    const node = new Node(
      key,
      tomlNode.name ?? key,
      tomlNode.macAddresses ?? [],
      tomlNode.config || {},
      tomlNode.description);
    for (const [key, tomlConnection] of Object.entries(tomlNode.connection ?? {})) {
      const network = networks.get(key);
      if (!network) {
        throw new Error(`Network ${key} not found for node ${node.key}`);
      }
      const connection = new Connection(
        node,
        network,
        tomlConnection.hostname ?? node.name,
        tomlConnection.config || {},
        tomlConnection.ipAddresses ?? [],
      );
      network.connections.push(connection);
      node.connections.push(connection);
    }
    nodes.set(key, node);
  }

  return new Inventory(nodes, networks);
}

export async function saveInventory(inventory: Inventory, outputPath: string): Promise<void> {
  let tomlInventory: TomlInventory = { network: {}, node: {} };

  for(const network of inventory.networks.values()) {
    tomlInventory.network![network.key] = {
      name: network.name === network.key ? undefined : network.name,
      vlan: network.vlan,
      dns: network.dns,
      dhcpServer: network.dhcpServer,
      subdomain: network.subdomain,
      description: network.description,
    };
  }

  for(const node of inventory.nodes.values()) {
    let connections: Record<string, TomlConnection> = {};
    for(const connection of node.connections) {
      connections[connection.network.key] = {
        hostname: connection.hostname,
        ipAddresses: connection.ipv4Addresses,
      };
    }
    tomlInventory.node![node.key] = {
      name: node.name === node.key ? undefined : node.name,
      description: node.description,
      macAddresses: node.macAddresses.length ? node.macAddresses : undefined,
      connection: connections,
    };
  }

  const tomlString = TOML.stringify(tomlInventory);
  await writeFile(outputPath, tomlString);
}
