variable "cluster_name" {
  description = "Name of the AKS cluster (also used as the DNS prefix)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the cluster and its identities are created in."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. uaenorth, eastus)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes control-plane and node-pool version (e.g. \"1.30\")."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID used for Azure RBAC on the cluster."
  type        = string
}

variable "vnet_subnet_ids" {
  description = <<-EOT
    Ordered list of subnet resource IDs available to the cluster's node pools.
    Each node pool selects its subnet by index via `subnet_index`.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.vnet_subnet_ids) > 0
    error_message = "At least one subnet ID must be supplied in vnet_subnet_ids."
  }
}

variable "node_pools" {
  description = <<-EOT
    Map of node pools keyed by pool name. A pool named "system" is REQUIRED and
    becomes the cluster's default (CriticalAddonsOnly) node pool; all other keys
    become user node pools. A pool named "ai" is tainted for GPU workloads.
    Each value defines:
      vm_size      - Azure VM SKU (required)
      min          - minimum node count when autoscaling (required)
      max          - maximum node count when autoscaling (required)
      subnet_index - index into vnet_subnet_ids for this pool (required)
  EOT
  type = map(object({
    vm_size      = string
    min          = number
    max          = number
    subnet_index = number
  }))

  validation {
    condition     = contains(keys(var.node_pools), "system")
    error_message = "node_pools must contain a pool named \"system\"."
  }
}

variable "pod_cidr" {
  description = "CIDR range for kubenet pod IPs. Must not overlap the VNet address space."
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR range for Kubernetes service ClusterIPs. Must not overlap the VNet or pod CIDR."
  type        = string
  default     = "10.245.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address of the in-cluster DNS service. Must be within service_cidr."
  type        = string
  default     = "10.245.0.10"
}

variable "api_server_authorized_ip_ranges" {
  description = "List of CIDRs allowed to reach the public API server. Empty list disables the allow-list."
  type        = list(string)
  default     = []
}

variable "acr_id" {
  description = "Resource ID of an Azure Container Registry to grant AcrPull on. Null skips the role assignment."
  type        = string
  default     = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for the OMS agent (Container Insights). Null disables monitoring."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
