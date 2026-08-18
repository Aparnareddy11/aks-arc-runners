variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Microsoft Entra tenant ID used for remote state authentication"
  type        = string
}

variable "client_id" {
  description = "Microsoft Entra client ID used for remote state OIDC authentication"
  type        = string
}

variable "tf_state_resource_group" {
  description = "Resource group containing the shared Terraform state storage account"
  type        = string
}

variable "tf_state_storage_account" {
  description = "Storage account containing the infrastructure Terraform state"
  type        = string
}

variable "tf_state_container" {
  description = "Blob container containing the infrastructure Terraform state"
  type        = string
}

variable "infra_tf_state_key" {
  description = "Blob key of the infrastructure Terraform state"
  type        = string
}

variable "runner_image" {
  description = "Full container image reference used by ARC runner pods"
  type        = string
  default     = "ghcr.io/actions/actions-runner:latest"
}

variable "arc_runner_namespace" {
  description = "Kubernetes namespace for ARC listener and runner pods"
  type        = string
  default     = "arc-runners"
}

variable "arc_controller_namespace" {
  description = "Kubernetes namespace for ARC controller pods"
  type        = string
  default     = "arc-systems"
}

variable "arc_chart_version" {
  description = "Pinned version of the ARC controller and runner scale set Helm charts"
  type        = string
  default     = "0.12.1"
}

variable "github_config_url" {
  description = "GitHub organization or repository URL where the runner scale set is registered"
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID used by ARC"
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID used by ARC"
  type        = string
  sensitive   = true
}

variable "github_app_private_key" {
  description = "PEM private key for the GitHub App used by ARC"
  type        = string
  sensitive   = true
}

variable "runner_scale_set_name" {
  description = "Runner scale set name used by workflows in the runs-on field"
  type        = string
  default     = "arc-runner-set"
}

variable "min_runners" {
  description = "Minimum number of idle runner pods"
  type        = number
  default     = 0
}

variable "max_runners" {
  description = "Maximum number of runner pods"
  type        = number
  default     = 10
}

variable "runner_container_mode" {
  description = "ARC container mode: dind, kubernetes, kubernetes-novolume, or null for standard runner jobs"
  type        = string
  default     = null
}
