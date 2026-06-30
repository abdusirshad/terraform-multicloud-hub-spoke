# Module: `azure-bastion`

Deploys an Azure Bastion host (Standard SKU by default) with a dedicated static
Standard public IP. Bastion provides browser- and native-client RDP/SSH access to
VMs and node pools inside the VNet **without** exposing any public IPs on those
resources — the zero-trust jump-box for the hub.

## Requirements

- The `subnet_id` MUST point at a subnet named exactly `AzureBastionSubnet`
  (Azure enforces this name). The `azure-vnet` module creates such a subnet when
  you include an `AzureBastionSubnet` key in its `subnets` map.
- The Standard SKU is required for `scale_units` and native-client `tunneling`.

## Usage

```hcl
module "bastion" {
  source              = "../../modules/azure-bastion"
  name                = "bastion-hub-dev"
  resource_group_name = azurerm_resource_group.hub.name
  location            = "uaenorth"
  subnet_id           = module.hub_vnet.subnet_ids["AzureBastionSubnet"]
  sku                 = "Standard"
  tags                = { environment = "dev" }
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Bastion host name. |
| `resource_group_name` | `string` | — | Resource group. |
| `location` | `string` | — | Azure region. |
| `subnet_id` | `string` | — | ID of the `AzureBastionSubnet`. |
| `sku` | `string` | `Standard` | `Basic` or `Standard`. |
| `scale_units` | `number` | `2` | Scale units (Standard only). |
| `tunneling_enabled` | `bool` | `true` | Native-client tunneling (Standard only). |
| `tags` | `map(string)` | `{}` | Tags. |

## Outputs

| Name | Description |
|------|-------------|
| `bastion_id` | Bastion host resource ID. |
| `bastion_dns_name` | Bastion DNS name. |
| `public_ip_address` | Allocated public IP. |
