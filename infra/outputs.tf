output "resource_group_name" {
  description = "Name of the Azure resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "azure_portal_url" {
  description = "Azure portal URL for the AKS cluster"
  value       = "https://portal.azure.com/#resource${azurerm_kubernetes_cluster.main.id}/overview"
}
