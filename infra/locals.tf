locals {
  tags = merge(
    {
      environment = var.environment
      managed_by  = "terraform"
      workload    = "github-actions-runners"
    },
    var.tags
  )
}