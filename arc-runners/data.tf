data "terraform_remote_state" "infra" {
  backend = "azurerm"

  config = {
    resource_group_name  = var.tf_state_resource_group
    storage_account_name = var.tf_state_storage_account
    container_name       = var.tf_state_container
    key                  = var.infra_tf_state_key
    use_azuread_auth     = true
    subscription_id      = var.subscription_id
    tenant_id            = var.tenant_id
    client_id            = var.client_id
  }
}

data "azurerm_kubernetes_cluster" "main" {
  name                = data.terraform_remote_state.infra.outputs.aks_cluster_name
  resource_group_name = data.terraform_remote_state.infra.outputs.resource_group_name
}
