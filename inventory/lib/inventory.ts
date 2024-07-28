const PRIMARY_NETWORK_NAME = "primary";

export class Inventory {
  constructor(
    public nodes: Map<string, Node>,
    public networks: Map<string, Network>) {}
}

export class Node {
  public connections: Connection[] = [];

  constructor(
    public key: string,
    public name: string,
    public macAddresses: string[],
    public config?: Record<string, unknown>,
    public description?: string,
  ) { }
}

export class Network {
  public connections: Connection[] = [];

  constructor(
    public key: string,
    public name: string,
    public dns: boolean,
    public vlan: number,
    public external: boolean,
    public subdomain: string,
    public description: string,
    public dhcpServer?: string,
    public config?: Record<string, unknown>,
  ) { }
}

export class Connection {
  constructor(
    public node: Node,
    public network: Network,
    public hostname: string,
    public ipv4Addresses: string[],
    public config?: Record<string, unknown>,
  ) {}

  get fqdn() {
    return `${this.hostname}.${this.network.subdomain}.analogrelay.net`;
  }
}