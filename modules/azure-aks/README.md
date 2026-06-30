# Module: `azure-aks`

Provisions a production-shaped AKS cluster with:

- **Kubenet** networking backed by a user-managed route table associated with every
  AKS subnet (the standard kubenet multi-subnet pattern).
- A dedicated **system** node pool (`CriticalAddonsOnly`) plus arbitrary user node
  pools driven from a `node_pools` map — a pool named `ai` is automatically tainted
  `nvidia.com/gpu=true:NoSchedule` for GPU workloads.
- Two **user-assigned managed identities** (control-plane + kubelet) with the
  control plane granted *Managed Identity Operator* over the kubelet identity.
- Optional **AcrPull** role assignment for zero-credential image pulls.
- **Azure RBAC** for Kubernetes authorization, API-server IP allow-listing, an
  optional **Container Insights** (OMS) agent, and a weekly maintenance window.

## Usage

```hcl
module "aks" {
  source              = "../../modules/azure-aks"
  cluster_name        = "aks-dev-001"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = "uaenorth"
  kubernetes_version  = "1.30"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  vnet_subnet_ids = module.spoke_vnet.subnet_ids_list

  node_pools = {
    system = { vm_size = "Standard_D4s_v5", min = 1, max = 3, subnet_index = 0 }
    ai     = { vm_size = "Standard_NC4as_T4_v3", min = 0, max = 4, subnet_index = 1 }
    app    = { vm_size = "Standard_D8s_v5", min = 2, max = 10, subnet_index = 2 }
  }

  api_server_authorized_ip_ranges = ["203.0.113.0/24"]
  acr_id                          = azurerm_container_registry.acr.id

  tags = { environment = "dev" }
}
```

## Notes on the bug fixes

This module was repaired from an earlier draft:

- Removed a broken/unused local that referenced
  `network_profile[0].load_balancer_profile[0].effective_outbound_ips[0].id`
  (no `load_balancer_profile` block was configured, and `effective_outbound_ips`
  is not an addressable object list).
- The kubenet route table is now created once and associated with **all** AKS
  subnets via `azurerm_subnet_route_table_association`, which is coherent with the
  kubenet networking model.
- Updated to **azurerm 4.x** attribute names (`auto_scaling_enabled`,
  `bgp_route_propagation_enabled`) and made `oms_agent` / `acr_id` optional.
- The default node pool now selects its subnet by `subnet_index` (was hard-coded
  to index `0`), matching the documented `node_pools` contract.

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cluster_name` | `string` | — | Cluster name / DNS prefix. |
| `resource_group_name` | `string` | — | Resource group. |
| `location` | `string` | — | Azure region. |
| `kubernetes_version` | `string` | — | K8s version. |
| `tenant_id` | `string` | — | Azure AD tenant for Azure RBAC. |
| `vnet_subnet_ids` | `list(string)` | — | Subnet IDs available to node pools. |
| `node_pools` | `map(object)` | — | Node pools (must include `system`). |
| `pod_cidr` | `string` | `10.244.0.0/16` | Kubenet pod CIDR. |
| `service_cidr` | `string` | `10.245.0.0/16` | Service ClusterIP CIDR. |
| `dns_service_ip` | `string` | `10.245.0.10` | In-cluster DNS IP. |
| `api_server_authorized_ip_ranges` | `list(string)` | `[]` | API-server allow-list. |
| `acr_id` | `string` | `null` | ACR to grant AcrPull on. |
| `log_analytics_workspace_id` | `string` | `null` | Log Analytics workspace for OMS agent. |
| `tags` | `map(string)` | `{}` | Tags. |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_id` | AKS cluster resource ID. |
| `cluster_name` | Cluster name. |
| `cluster_fqdn` | API-server FQDN. |
| `node_resource_group` | Auto-generated node RG. |
| `control_plane_identity_id` | Control-plane identity ID. |
| `kubelet_identity_object_id` | Kubelet identity principal ID. |
| `kube_config_raw` | Raw kubeconfig (sensitive). |
| `route_table_id` | Kubenet route-table ID. |
