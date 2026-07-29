# vnet-with-restrictions

Terraform that deploys a **VNet, subnet, NSG and route table** using [Azure Verified Modules](https://aka.ms/avm), and locks them with an **Azure Deployment Stack** so that only one nominated user can modify or delete them.

## What it deploys

| Resource | Source |
|----------|--------|
| Resource group | `azurerm_resource_group` |
| Virtual network + subnet | `Azure/avm-res-network-virtualnetwork/azurerm` |
| Network security group | `Azure/avm-res-network-networksecuritygroup/azurerm` |
| Route table | `Azure/avm-res-network-routetable/azurerm` |
| Deployment stack (deny lock) | `azapi_resource` – `Microsoft.Resources/deploymentStacks` |

The subnet is associated with both the NSG and the route table.

## How the restriction works

The deployment stack uses `denySettings`:

- `mode = "denyWriteAndDelete"` – write and delete are denied.
- `applyToChildScopes = true` – the deny assignment covers the whole resource group.
- `excludedPrincipals` – the **one** user (`modify_principal_object_id`) plus any
  principals in `additional_excluded_principal_ids` are exempt and can still modify.

> **Important:** Add the identity Terraform authenticates as to
> `additional_excluded_principal_ids`. Otherwise the deny assignment blocks
> Terraform itself on the next `apply`.

Deleting the stack **detaches** (does not delete) the resources, so removing the
lock never destroys your network.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set modify_principal_object_id (and additional_excluded_principal_ids)

terraform init
terraform plan
terraform apply
```

Get a user's object ID with: `az ad user show --id user@contoso.com --query id -o tsv`
