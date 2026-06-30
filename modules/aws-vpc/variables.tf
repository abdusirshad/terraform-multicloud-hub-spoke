variable "name" {
  description = "Name prefix applied to the VPC and its child resources."
  type        = string
}

variable "cidr_block" {
  description = "Primary CIDR block for the VPC."
  type        = string
}

variable "azs" {
  description = "List of availability zones to spread subnets across (e.g. [\"us-east-1a\", \"us-east-1b\"])."
  type        = list(string)

  validation {
    condition     = length(var.azs) > 0
    error_message = "At least one availability zone must be supplied."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets. Index i is placed in azs[i % length(azs)]."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets. Index i is placed in azs[i % length(azs)]."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway (single, in the first public subnet) for private-subnet egress."
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames on the VPC (required for many AWS services)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to all resources created by this module."
  type        = map(string)
  default     = {}
}
