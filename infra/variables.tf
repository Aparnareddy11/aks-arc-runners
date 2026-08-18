variable "subscription_id" {
  description = "Azure subscription ID; can be omitted when ARM_SUBSCRIPTION_ID is set"
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID; can be omitted to use the current subscription tenant"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for the resource group and AKS cluster"
  type        = string
  default     = "southeastasia"
}

variable "name_prefix" {
  description = "Short lowercase prefix used in Azure resource names"
  type        = string
  default     = "arc"
}

variable "environment" {
  description = "Environment name used in resource names and tags"
  type        = string
  default     = "dev"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version; null selects the current Azure default"
  type        = string
  default     = null
}

variable "aks_sku_tier" {
  description = "AKS control plane SKU tier"
  type        = string
  default     = "Free"
}

variable "node_vm_size" {
  description = "Virtual machine size for the default system node pool"
  type        = string
  default     = "Standard_D4ds_v5"
}

variable "node_min_count" {
  description = "Minimum node count for the autoscaling default node pool"
  type        = number
  default     = 1
}

variable "node_max_count" {
  description = "Maximum node count for the autoscaling default node pool"
  type        = number
  default     = 3
}

variable "availability_zones" {
  description = "Availability zones for the default node pool"
  type        = list(string)
  default     = ["2"]
}

variable "tags" {
  description = "Additional tags applied to Azure resources"
  type        = map(string)
  default     = {}
}
