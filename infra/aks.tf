resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg-${var.environment}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.name_prefix}-aks-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.name_prefix}-${var.environment}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.aks_sku_tier

  default_node_pool {
    name                 = "system"
    vm_size              = var.node_vm_size
    auto_scaling_enabled = true
    min_count            = var.node_min_count
    max_count            = var.node_max_count
    os_disk_size_gb      = 128
    os_disk_type         = "Managed"
    type                 = "VirtualMachineScaleSets"
    zones                = var.availability_zones
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = var.tenant_id
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  oidc_issuer_enabled                 = true
  workload_identity_enabled           = true
  role_based_access_control_enabled   = true
  private_cluster_enabled             = false
  private_cluster_public_fqdn_enabled = true

  tags = local.tags
}