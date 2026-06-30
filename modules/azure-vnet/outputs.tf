output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "address_space" {
  description = "CIDR blocks assigned to the virtual network."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "subnet_ids_list" {
  description = "List of subnet resource IDs (ordered by subnet name)."
  value       = [for name in sort(keys(azurerm_subnet.this)) : azurerm_subnet.this[name].id]
}

output "nsg_id" {
  description = "Resource ID of the shared workload network security group."
  value       = azurerm_network_security_group.workload.id
}
