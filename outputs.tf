output "resource_group_id" {
  description = "ID of the resource group."
  value       = azurerm_resource_group.this.id
}

output "vnet_id" {
  description = "Resource ID of the virtual network."
  value       = module.vnet.resource_id
}

output "subnet_ids" {
  description = "Map of subnet keys to subnet resource IDs."
  value       = { for k, v in module.vnet.subnets : k => v.resource_id }
}

output "nsg_id" {
  description = "Resource ID of the network security group."
  value       = module.nsg.resource_id
}

output "route_table_id" {
  description = "Resource ID of the route table."
  value       = module.route_table.resource_id
}

output "deployment_stack_id" {
  description = "Resource ID of the deployment stack enforcing the deny assignment."
  value       = azapi_resource.deny_stack.id
}
