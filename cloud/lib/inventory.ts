import * as YAML from "yaml";
import { readFile } from "node:fs/promises";
import { resolve, join } from "node:path";

export interface Inventory {
  nodes: InventoryNode[],
}

export interface InventoryNode {
  name?: string,
  domain?: string,
  description?: string,
  macAddresses?: string[],
  ipAddresses?: string[],
}

export async function loadInventory(fleetRoot?: string): Promise<Inventory> {
  if (!fleetRoot) {
    fleetRoot = resolve(join(process.cwd(), ".."));
  }
  const inventoryPath = join(fleetRoot, "machines", "inventory.yaml");
  const inventoryContent = await readFile(inventoryPath, { encoding: "utf-8" });
  return YAML.parse(inventoryContent);
}

export async function allNodesWithName(domain: string, fleetRoot?: string): Promise<InventoryNode[]> {
  const inventory = await loadInventory(fleetRoot);
  return inventory.nodes.filter(node => node.name && (node.domain === domain || (node.domain === undefined && domain === "node")));
}