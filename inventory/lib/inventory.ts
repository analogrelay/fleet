import * as YAML from "yaml";
import { readFile } from "node:fs/promises";
import { resolve, join } from "node:path";

const PRIMARY_NETWORK_NAME = "primary";

export class Inventory {
  constructor(
    public nodes: Map<string, Node>,
    public networks: Map<string, Network>) {}
}

export class Node {
  public connections: Connection[] = [];

  constructor(
    public name: string,
    public macAddresses: string[],
  ) { }

  static fromYaml(yaml: YamlNode): Node {
    if(!yaml.name) {
      throw new Error("Invalid inventory: Node has no name");
    }
    return new Node(
      yaml.name,
      yaml.macAddresses || [],
    );
  }
}

export class Network {
  public connections: Connection[] = [];

  constructor(
    public name: string,
    public dns: boolean,
    public vlan: number,
    public subdomain: string,
    public description: string,
    public dhcpServer?: string,
  ) { }

  static fromYaml(yaml: YamlNetwork): Network {
    if(!yaml.name) {
      throw new Error("Invalid inventory: Network has no name");
    }
    if(yaml.id === undefined) {
      throw new Error("Invalid inventory: Network has no ID");
    }
    if(!yaml.subdomain) {
      throw new Error("Invalid inventory: Network has no Subdomain");
    }
    return new Network(
      yaml.name,
      !!yaml.dns,
      yaml.id,
      yaml.subdomain,
      yaml.description || "",
      yaml.dhcpServer);
  }
}

export class Connection {
  constructor(
    public node: Node,
    public network: Network,
    public hostname: string,
    public ipv4Addresses: string[],
  ) {}

  get fqdn() {
    return `${this.hostname}.${this.network.subdomain}.analogrelay.net`;
  }
}

interface YamlInventory {
  networks?: YamlNetwork[],
  nodes?: YamlNode[],
}

interface YamlNetwork {
  id?: number,
  dns?: boolean,
  dhcpServer?: string,
  name?: string,
  domain?: string,
  subdomain?: string,
  description?: string,
}

interface YamlNode {
  /** The host name of the node */
  name?: string,
  macAddresses?: string[],
  connections?: YamlConnection[]
}

interface YamlConnection {
  network?: string,
  hostname?: string,
  ipAddresses?: string[],
}

function parseInventory(yaml: YamlInventory): Inventory {
  // Load the networks first
  const networks = toMap((yaml.networks || []).map(Network.fromYaml), n => n.name);
  const primaryNetwork = networks.get(PRIMARY_NETWORK_NAME);
  if(!primaryNetwork) {
    throw new Error("Invalid inventory: No primary network defined");
  }

  // Now iterate through nodes to build up the node map
  const nodes = new Map<string, Node>();
  for(const yamlNode of yaml.nodes || []) {
    // Create the node object
    const node = Node.fromYaml(yamlNode);
    if (nodes.has(node.name)) {
      throw new Error(`Invalid inventory: Duplicate nodes with name ${node.name}`);
    }
    nodes.set(node.name, node);

    // Create connections
    for(const yamlConnection of yamlNode.connections || []) {
      if(!yamlConnection.network) {
        throw new Error(`Invalid inventory: Node ${node.name} has connection with no network specified`);
      }
      const network = networks.get(yamlConnection.network);
      if(!network) {
        throw new Error(`Invalid inventory: Node ${node.name} has connection to unknown network ${yamlConnection.network}`);
      }
      const hostname = yamlConnection.hostname ?? node.name;
      const connection = new Connection(
        node,
        network,
        hostname,
        yamlConnection.ipAddresses || [],
      )
      node.connections.push(connection);
      network.connections.push(connection);
    }
  }

  return new Inventory(nodes, networks);
}

let loadedInventory: Inventory | undefined = undefined;
export async function loadInventory(inventoryPath?: string): Promise<Inventory> {
  if (loadedInventory !== undefined) {
    return loadedInventory
  }

  if (!inventoryPath) {
    inventoryPath = resolve(join(process.cwd(), "inventory.yaml"));
  }
  const inventoryContent = await readFile(inventoryPath, { encoding: "utf-8" });
  const yamlInventory = YAML.parse(inventoryContent);
  loadedInventory = parseInventory(yamlInventory);
  return loadedInventory;
}

function toMap<T, K>(items: T[], keySelector: (item: T) => K): Map<K, T> {
  const map = new Map<K, T>();
  for (const item of items) {
    const key = keySelector(item);
    if(map.has(key)) {
      throw new Error(`Duplicate key '${key}' found in map items`);
    }
    map.set(key, item);
  }
  return map;
}