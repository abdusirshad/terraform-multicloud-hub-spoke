output "hub_vnet_id" {
  description = "Resource ID of the hub VNet."
  value       = module.hub_vnet.vnet_id
}

output "spoke_vnet_id" {
  description = "Resource ID of the AKS spoke VNet."
  value       = module.spoke_vnet.vnet_id
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster."
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS API server."
  value       = module.aks.cluster_fqdn
}

output "acr_login_server" {
  description = "Login server of the Azure Container Registry."
  value       = azurerm_container_registry.acr.login_server
}

output "bastion_dns_name" {
  description = "DNS name of the Azure Bastion host."
  value       = module.bastion.bastion_dns_name
}

output "aws_vpc_id" {
  description = "ID of the AWS spoke VPC."
  value       = module.aws_vpc.vpc_id
}

output "aws_private_subnet_ids" {
  description = "Private subnet IDs in the AWS spoke VPC."
  value       = module.aws_vpc.private_subnet_ids
}
