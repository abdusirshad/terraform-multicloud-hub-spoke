resource "azurerm_virtual_network" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  address_space       = var.address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value.cidr]
  service_endpoints    = each.value.service_endpoints

  private_endpoint_network_policies = each.value.private_endpoint_policies ? "Enabled" : "Disabled"

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    content {
      name = "delegation"
      service_delegation {
        name    = delegation.value
        actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}

# Shared workload NSG — Azure-reserved subnets (Bastion, Gateway) must not have an NSG
# with restrictive rules attached, so they are excluded from the association below.
resource "azurerm_network_security_group" "workload" {
  name                = "nsg-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_network_security_rule" "workload" {
  for_each = var.nsg_rules

  name                        = each.key
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.workload.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
}

resource "azurerm_subnet_network_security_group_association" "workload" {
  for_each = {
    for name, subnet in var.subnets : name => subnet
    if !contains(["AzureBastionSubnet", "GatewaySubnet"], name)
  }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.workload.id
}

resource "azurerm_virtual_network_peering" "this" {
  for_each = var.peerings

  name                         = each.key
  resource_group_name          = var.resource_group_name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = each.value.remote_vnet_id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = each.value.allow_forwarded
  allow_gateway_transit        = each.value.allow_gateway_transit
  use_remote_gateways          = each.value.use_remote_gateways
}
