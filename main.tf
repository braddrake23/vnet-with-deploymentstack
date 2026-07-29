resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Network Security Group (AVM) ------------------------------------------------
module "nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "~> 0.5"

  name                = var.nsg_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  security_rules = {
    allow_vnet_inbound = {
      name                       = "Allow-VNet-Inbound"
      access                     = "Allow"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "*"
      source_address_prefix      = "VirtualNetwork"
      source_port_range          = "*"
      destination_address_prefix = "VirtualNetwork"
      destination_port_range     = "*"
    }
    deny_all_inbound = {
      name                       = "Deny-All-Inbound"
      access                     = "Deny"
      direction                  = "Inbound"
      priority                   = 4096
      protocol                   = "*"
      source_address_prefix      = "*"
      source_port_range          = "*"
      destination_address_prefix = "*"
      destination_port_range     = "*"
    }
  }
}

# Route Table (AVM) ----------------------------------------------------------
module "route_table" {
  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "~> 0.4"

  name                = var.route_table_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  routes = {
    default_to_firewall = {
      name           = "default-via-vnetlocal"
      address_prefix = "10.10.0.0/16"
      next_hop_type  = "VnetLocal"
    }
  }
}

# Virtual Network + Subnet (AVM) ---------------------------------------------
# The subnet is created inline and associated with the NSG and route table above.
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "~> 0.8"

  name          = var.vnet_name
  location      = azurerm_resource_group.this.location
  parent_id     = azurerm_resource_group.this.id
  address_space = toset(var.address_space)
  tags          = var.tags

  subnets = {
    workload = {
      name             = var.subnet_name
      address_prefixes = var.subnet_address_prefixes

      network_security_group = {
        id = module.nsg.resource_id
      }

      route_table = {
        id = module.route_table.resource_id
      }
    }
  }
}
