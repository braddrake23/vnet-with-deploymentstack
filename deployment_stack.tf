# ---------------------------------------------------------------------------
# Azure Deployment Stack with a deny assignment.
#
# IMPORTANT: A deployment stack's deny assignment only covers the resources the
# stack *manages*. An empty template manages zero resources, so an RG-scoped
# stack with an empty template produces a deny assignment that protects nothing
# (applyToChildScopes cascades from zero managed resources). An RG-scoped stack
# also cannot manage its own parent resource group.
#
# To lock this ONE resource group we therefore create the stack at *subscription*
# scope and let its template manage the resource group itself. The deny
# assignment is placed on each managed resource at that resource's own scope, so
# it is created AT THE RESOURCE GROUP scope (NOT the whole subscription); with
# applyToChildScopes = true it cascades over the RG and every child resource in
# it. Other resource groups in the subscription are unaffected.
#
# The stack adopts the already-existing resource group (created by Terraform
# above) as a managed resource. denySettings use mode "denyWriteAndDelete",
# blocking EVERY principal from modifying or deleting the network resources
# EXCEPT the principals listed in excludedPrincipals (the single "modify" user,
# plus any additional principals such as the identity Terraform runs as).
#
# depends_on ensures the resources exist before the lock is applied.
# ---------------------------------------------------------------------------
data "azurerm_subscription" "current" {}

resource "azapi_resource" "deny_stack" {
  type      = "Microsoft.Resources/deploymentStacks@2024-03-01"
  name      = var.deployment_stack_name
  parent_id = data.azurerm_subscription.current.id
  location  = var.location
  tags      = var.tags

  body = {
    properties = {
      description = "Locks the restricted VNet resources. Only excluded principals may write/delete."

      denySettings = {
        mode               = "denyWriteAndDelete"
        applyToChildScopes = true
        excludedPrincipals = distinct(concat(
          [var.modify_principal_object_id],
          var.additional_excluded_principal_ids,
        ))
        # Reading is always permitted; role assignment changes are excluded so that
        # access management is not permanently frozen by the lock.
        excludedActions = [
          "Microsoft.Authorization/roleAssignments/write",
          "Microsoft.Authorization/roleAssignments/delete",
        ]
      }

      # Deleting the stack detaches (does not delete) the resources and RG, so the
      # network survives if the lock is ever removed.
      actionOnUnmanage = {
        resources      = "detach"
        resourceGroups = "detach"
      }

      # Subscription-scoped template whose only managed resource is the resource
      # group. This makes the RG the stack's managed resource, so the deny
      # assignment is scoped to the RG (and its children via applyToChildScopes).
      template = {
        "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/subscriptionDeploymentTemplate.json#"
        contentVersion = "1.0.0.0"
        resources = [
          {
            type       = "Microsoft.Resources/resourceGroups"
            apiVersion = "2021-04-01"
            name       = var.resource_group_name
            location   = var.location
            tags       = var.tags
          }
        ]
      }
    }
  }

  schema_validation_enabled = false

  depends_on = [
    module.vnet,
    module.nsg,
    module.route_table,
  ]
}
