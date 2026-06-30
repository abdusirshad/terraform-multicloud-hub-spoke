# Module: `azure-vnet`

Creates an Azure Virtual Network with a map of subnets, a shared workload NSG
(with rules applied per a map), optional VNet peerings, and per-subnet NSG
associations. Designed for both **hub** and **spoke** VNets in a hub-and-spoke
topology — the same module is reused on both sides; only the `peerings` and
`subnets` inputs differ.

## Behaviour

- Subnets are defined as a `map(object)` so callers add/remove subnets without
  editing the module.
- The reserved subnets `AzureBastionSubnet` and `GatewaySubnet` are intentionally
  **excluded** from the workload-NSG association (Azure rejects restrictive NSGs
  on those subnets).
- `peerings` lets you wire a hub to its spokes. Set `allow_gateway_transit = true`
  on the hub side and `use_remote_gateways = true` on the spoke side when the hub
  hosts a VPN/ExpressRoute gateway.

## Usage

```hcl
module "hub_vnet" {
  source              = "../../modules/azure-vnet"
  name                = "vnet-hub-dev"
  resource_group_name = azurerm_resource_group.hub.name
  location            = "uaenorth"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    AzureBastionSubnet = { cidr = "10.0.0.0/27" }
    shared-services    = { cidr = "10.0.1.0/24", service_endpoints = ["Microsoft.KeyVault"] }
  }

  nsg_rules = {
    allow-https-inbound = {
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "443"
    }
  }

  tags = { environment = "dev" }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | VNet name. |
| `resource_group_name` | `string` | — | Resource group for the VNet and subnets. |
| `location` | `string` | — | Azure region. |
| `address_space` | `list(string)` | — | CIDR blocks for the VNet. |
| `dns_servers` | `list(string)` | `[]` | Custom DNS servers (empty = Azure DNS). |
| `subnets` | `map(object)` | — | Subnets keyed by name. |
| `peerings` | `map(object)` | `{}` | Outbound VNet peerings keyed by name. |
| `nsg_rules` | `map(object)` | `{}` | Security rules for the shared workload NSG. |
| `tags` | `map(string)` | `{}` | Tags applied to all resources. |

## Outputs

| Name | Description |
|------|-------------|
| `vnet_id` | Resource ID of the VNet. |
| `vnet_name` | Name of the VNet. |
| `address_space` | CIDR blocks assigned to the VNet. |
| `subnet_ids` | Map of subnet name → subnet ID. |
| `subnet_ids_list` | List of subnet IDs ordered by subnet name. |
| `nsg_id` | Resource ID of the workload NSG. |
