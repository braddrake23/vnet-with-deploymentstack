variable "location" {
  type        = string
  description = "Azure region for all resources."
  default     = "uksouth"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that will hold the network resources."
  default     = "rg-vnet-restricted-uksouth-001"
}

variable "vnet_name" {
  type        = string
  description = "Name of the virtual network."
  default     = "vnet-restricted-uksouth-001"
}

variable "address_space" {
  type        = list(string)
  description = "Address space of the virtual network."
  default     = ["10.10.0.0/16"]
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet."
  default     = "snet-workload-001"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet."
  default     = ["10.10.1.0/24"]
}

variable "nsg_name" {
  type        = string
  description = "Name of the network security group."
  default     = "nsg-workload-001"
}

variable "route_table_name" {
  type        = string
  description = "Name of the route table."
  default     = "rt-workload-001"
}

variable "deployment_stack_name" {
  type        = string
  description = "Name of the Azure Deployment Stack used to lock the resources."
  default     = "stack-vnet-restricted-001"
}

variable "modify_principal_object_id" {
  type        = string
  description = <<-DESC
    The Entra ID object (principal) ID of the ONE user who is allowed to modify the
    deployment/resources. Every other principal is denied write and delete by the
    deployment stack's deny assignment.
  DESC

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.modify_principal_object_id))
    error_message = "modify_principal_object_id must be a GUID (the user's Entra ID object ID)."
  }
}

variable "additional_excluded_principal_ids" {
  type        = list(string)
  description = <<-DESC
    Extra principal object IDs to exclude from the deny assignment. You should normally
    include the identity Terraform authenticates as (e.g. your service principal /
    deploying user) here, otherwise the deny assignment will block Terraform itself from
    updating these resources on subsequent applies.
  DESC
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default = {
    environment = "shared"
    workload    = "restricted-network"
    managed_by  = "terraform"
  }
}
