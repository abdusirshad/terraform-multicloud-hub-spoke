resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # Kubenet networking — pods routed via a user-managed route table (see below).
  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "standard"
    pod_cidr          = var.pod_cidr
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # User-assigned managed identity — no credential rotation required.
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks.id]
  }

  default_node_pool {
    name                         = "system"
    vm_size                      = var.node_pools["system"].vm_size
    vnet_subnet_id               = var.vnet_subnet_ids[var.node_pools["system"].subnet_index]
    min_count                    = var.node_pools["system"].min
    max_count                    = var.node_pools["system"].max
    auto_scaling_enabled         = true
    os_disk_type                 = "Managed"
    type                         = "VirtualMachineScaleSets"
    only_critical_addons_enabled = true
    orchestrator_version         = var.kubernetes_version
  }

  # ACR integration — AcrPull on the kubelet identity for zero-credential image pulls.
  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.aks_kubelet.client_id
    object_id                 = azurerm_user_assigned_identity.aks_kubelet.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_kubelet.id
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ip_ranges
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id == null ? [] : [1]
    content {
      log_analytics_workspace_id      = var.log_analytics_workspace_id
      msi_auth_for_monitoring_enabled = true
    }
  }

  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }

  tags = var.tags

  # The kubelet identity must hold the Managed Identity Operator / network role
  # on the kubelet identity before the cluster can consume it. Ordering via the
  # role assignment guarantees the identity exists first.
  depends_on = [
    azurerm_subnet_route_table_association.aks_subnets,
  ]
}

# Additional node pools (AI / GPU workloads, app tier).
resource "azurerm_kubernetes_cluster_node_pool" "extra" {
  for_each = { for k, v in var.node_pools : k => v if k != "system" }

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.vnet_subnet_ids[each.value.subnet_index]
  min_count             = each.value.min
  max_count             = each.value.max
  auto_scaling_enabled  = true
  os_disk_type          = "Managed"
  mode                  = "User"
  orchestrator_version  = var.kubernetes_version

  node_labels = {
    "workload-type" = each.key
  }

  node_taints = each.key == "ai" ? ["nvidia.com/gpu=true:NoSchedule"] : []

  tags = var.tags
}

# User-assigned identity for the AKS control plane.
resource "azurerm_user_assigned_identity" "aks" {
  name                = "id-${var.cluster_name}-cp"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# User-assigned identity for the kubelet (used for ACR pulls).
resource "azurerm_user_assigned_identity" "aks_kubelet" {
  name                = "id-${var.cluster_name}-kubelet"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# The control-plane identity needs Managed Identity Operator on the kubelet
# identity so it can assign it to the node pools.
resource "azurerm_role_assignment" "cp_operates_kubelet" {
  scope                = azurerm_user_assigned_identity.aks_kubelet.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# AcrPull role assignment — zero-credential image pulls (only when an ACR is supplied).
resource "azurerm_role_assignment" "acr_pull" {
  count = var.acr_id == null ? 0 : 1

  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aks_kubelet.principal_id
}

# Kubenet route table — AKS manages routes in it; associate every AKS subnet with it
# so pod CIDRs are routable across the node pools.
resource "azurerm_route_table" "aks_kubenet" {
  name                          = "rt-${var.cluster_name}-kubenet"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = true
  tags                          = var.tags
}

resource "azurerm_subnet_route_table_association" "aks_subnets" {
  for_each = toset(var.vnet_subnet_ids)

  subnet_id      = each.value
  route_table_id = azurerm_route_table.aks_kubenet.id
}
