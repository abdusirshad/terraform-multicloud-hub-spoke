variable "azure_subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure AD tenant ID (used for the provider and AKS Azure RBAC)."
  type        = string
}

variable "azure_location" {
  description = "Azure region for the hub and spoke."
  type        = string
  default     = "uaenorth"
}

variable "aws_region" {
  description = "AWS region for the spoke VPC."
  type        = string
  default     = "us-east-1"
}

variable "aws_azs" {
  description = "AWS availability zones for the spoke VPC subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "name_prefix" {
  description = "Short prefix applied to resource names (keep it lowercase, <= 12 chars)."
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "api_server_authorized_ip_ranges" {
  description = "CIDRs allowed to reach the AKS public API server."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied across both clouds."
  type        = map(string)
  default = {
    environment = "dev"
    project     = "multicloud-hub-spoke"
    managed_by  = "terraform"
  }
}
