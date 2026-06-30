variable "name" {
  description = "Name of the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the VNet and subnets are created in."
  type        = string
}

variable "location" {
  description = "Azure region (e.g. uaenorth, eastus)."
  type        = string
}

variable "address_space" {
  description = "List of CIDR blocks assigned to the VNet."
  type        = list(string)
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNet. Empty list uses Azure-provided DNS."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = <<-EOT
    Map of subnets to create, keyed by subnet name. Each value defines:
      cidr                       - CIDR block for the subnet (required)
      service_endpoints          - list of service endpoints to enable (optional)
      private_endpoint_policies  - whether to enforce private endpoint network policies (optional, default true)
      delegation                 - optional service delegation name (e.g. "Microsoft.ContainerInstance/containerGroups")
  EOT
  type = map(object({
    cidr                      = string
    service_endpoints         = optional(list(string), [])
    private_endpoint_policies = optional(bool, true)
    delegation                = optional(string, null)
  }))
}

variable "peerings" {
  description = <<-EOT
    Map of outbound VNet peerings keyed by peering name. Used to wire a hub VNet
    to its spokes (or vice-versa). Each value defines:
      remote_vnet_id        - resource ID of the remote VNet (required)
      allow_forwarded       - allow forwarded traffic (default true)
      allow_gateway_transit - allow gateway transit, set true on the hub side (default false)
      use_remote_gateways   - use the remote VNet's gateway, set true on spokes (default false)
  EOT
  type = map(object({
    remote_vnet_id        = string
    allow_forwarded       = optional(bool, true)
    allow_gateway_transit = optional(bool, false)
    use_remote_gateways   = optional(bool, false)
  }))
  default = {}
}

variable "nsg_rules" {
  description = <<-EOT
    Map of NSG security rules applied to the shared workload NSG, keyed by rule name.
    Subnets whose name is NOT "AzureBastionSubnet" or "GatewaySubnet" are associated
    with this NSG. Each value mirrors the azurerm_network_security_rule schema.
  EOT
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = optional(string, "*")
    destination_port_range     = optional(string, "*")
    source_address_prefix      = optional(string, "*")
    destination_address_prefix = optional(string, "*")
  }))
  default = {}
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
