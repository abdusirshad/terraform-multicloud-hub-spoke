output "bastion_id" {
  description = "Resource ID of the Bastion host."
  value       = azurerm_bastion_host.this.id
}

output "bastion_dns_name" {
  description = "DNS name of the Bastion host."
  value       = azurerm_bastion_host.this.dns_name
}

output "public_ip_address" {
  description = "Public IP address allocated to the Bastion host."
  value       = azurerm_public_ip.bastion.ip_address
}
