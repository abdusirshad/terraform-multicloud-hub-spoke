output "cluster_id" {
  description = "Resource ID of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS API server."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "node_resource_group" {
  description = "Auto-generated resource group that holds the cluster's node infrastructure."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "control_plane_identity_id" {
  description = "Resource ID of the control-plane user-assigned identity."
  value       = azurerm_user_assigned_identity.aks.id
}

output "kubelet_identity_object_id" {
  description = "Object (principal) ID of the kubelet identity — useful for granting further RBAC."
  value       = azurerm_user_assigned_identity.aks_kubelet.principal_id
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster (sensitive)."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "route_table_id" {
  description = "Resource ID of the kubenet route table associated with the AKS subnets."
  value       = azurerm_route_table.aks_kubenet.id
}
