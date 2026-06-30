locals {
  tags = var.tags
}

# ---------------------------------------------------------------------------
# Resource groups
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "hub" {
  name     = "rg-${var.name_prefix}-hub"
  location = var.azure_location
  tags     = local.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = "rg-${var.name_prefix}-spoke-aks"
  location = var.azure_location
  tags     = local.tags
}

# ---------------------------------------------------------------------------
# Azure Container Registry (image source for AKS, with AcrPull granted in-module)
# ---------------------------------------------------------------------------
resource "azurerm_container_registry" "acr" {
  name                = "acr${var.name_prefix}hubspoke"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.azure_location
  sku                 = "Standard"
  admin_enabled       = false
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# Hub VNet — shared services + Azure Bastion subnet
# ---------------------------------------------------------------------------
module "hub_vnet" {
  source = "../../modules/azure-vnet"

  name                = "vnet-${var.name_prefix}-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.azure_location
  address_space       = ["10.0.0.0/16"]

  subnets = {
    AzureBastionSubnet = { cidr = "10.0.0.0/27" }
    shared-services    = { cidr = "10.0.1.0/24", service_endpoints = ["Microsoft.KeyVault"] }
  }

  peerings = {
    "hub-to-spoke" = {
      remote_vnet_id        = module.spoke_vnet.vnet_id
      allow_gateway_transit = true
    }
  }

  nsg_rules = {
    allow-https-inbound = {
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "443"
    }
    deny-all-inbound = {
      priority                   = 4096
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Spoke VNet — AKS node-pool subnets
# ---------------------------------------------------------------------------
module "spoke_vnet" {
  source = "../../modules/azure-vnet"

  name                = "vnet-${var.name_prefix}-spoke-aks"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.azure_location
  address_space       = ["10.1.0.0/16"]

  subnets = {
    aks-system = { cidr = "10.1.0.0/22" }
    aks-ai     = { cidr = "10.1.4.0/22" }
    aks-app    = { cidr = "10.1.8.0/22" }
  }

  peerings = {
    "spoke-to-hub" = {
      remote_vnet_id      = module.hub_vnet.vnet_id
      use_remote_gateways = false
    }
  }

  tags = local.tags
}

# ---------------------------------------------------------------------------
# Azure Bastion in the hub
# ---------------------------------------------------------------------------
module "bastion" {
  source = "../../modules/azure-bastion"

  name                = "bas-${var.name_prefix}-hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = var.azure_location
  subnet_id           = module.hub_vnet.subnet_ids["AzureBastionSubnet"]
  sku                 = "Standard"
  tags                = local.tags
}

# ---------------------------------------------------------------------------
# AKS cluster in the spoke
# ---------------------------------------------------------------------------
module "aks" {
  source = "../../modules/azure-aks"

  cluster_name        = "aks-${var.name_prefix}-001"
  resource_group_name = azurerm_resource_group.spoke.name
  location            = var.azure_location
  kubernetes_version  = var.kubernetes_version
  tenant_id           = var.azure_tenant_id

  # Order matches the node_pools subnet_index values below.
  vnet_subnet_ids = [
    module.spoke_vnet.subnet_ids["aks-system"],
    module.spoke_vnet.subnet_ids["aks-ai"],
    module.spoke_vnet.subnet_ids["aks-app"],
  ]

  node_pools = {
    system = { vm_size = "Standard_D4s_v5", min = 1, max = 3, subnet_index = 0 }
    ai     = { vm_size = "Standard_NC4as_T4_v3", min = 0, max = 4, subnet_index = 1 }
    app    = { vm_size = "Standard_D8s_v5", min = 2, max = 10, subnet_index = 2 }
  }

  api_server_authorized_ip_ranges = var.api_server_authorized_ip_ranges
  acr_id                          = azurerm_container_registry.acr.id

  tags = local.tags
}

# ---------------------------------------------------------------------------
# AWS spoke VPC (EKS-ready subnet tagging)
# ---------------------------------------------------------------------------
module "aws_vpc" {
  source = "../../modules/aws-vpc"

  name       = "vpc-${var.name_prefix}-spoke"
  cidr_block = "10.20.0.0/16"
  azs        = var.aws_azs

  public_subnet_cidrs  = ["10.20.0.0/24", "10.20.1.0/24"]
  private_subnet_cidrs = ["10.20.10.0/24", "10.20.11.0/24"]

  enable_nat_gateway = true
  tags               = local.tags
}
