output "runner_image" {
  description = "Full container image reference used by ARC runner pods"
  value       = var.runner_image
}

output "arc_runner_namespace" {
  description = "Namespace containing ARC listeners and ephemeral runners"
  value       = kubernetes_namespace_v1.arc_runners.metadata[0].name
}

output "arc_controller_namespace" {
  description = "Namespace containing the ARC controller"
  value       = kubernetes_namespace_v1.arc_systems.metadata[0].name
}

output "runner_scale_set_name" {
  description = "Label to use in the GitHub Actions runs-on field"
  value       = var.runner_scale_set_name
}
