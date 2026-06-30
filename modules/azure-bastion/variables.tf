variable "name" {
  description = "Name of the Azure Bastion host."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the Bastion host and public IP are created in."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "subnet_id" {
  description = "Resource ID of the AzureBastionSubnet (must be named exactly \"AzureBastionSubnet\")."
  type        = string
}

variable "sku" {
  description = "Bastion SKU. \"Standard\" is required for native client / tunneling features."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Basic", "Standard"], var.sku)
    error_message = "sku must be either \"Basic\" or \"Standard\"."
  }
}

variable "scale_units" {
  description = "Number of scale units (2-50). Only honoured on the Standard SKU."
  type        = number
  default     = 2
}

variable "tunneling_enabled" {
  description = "Enable native-client tunneling (Standard SKU only)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
