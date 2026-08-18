resource "kubernetes_namespace_v1" "arc_systems" {
  metadata {
    name = var.arc_controller_namespace
    labels = {
      "app.kubernetes.io/part-of" = "actions-runner-controller"
    }
  }
}

resource "helm_release" "arc_controller" {
  name       = "arc-controller"
  namespace  = kubernetes_namespace_v1.arc_systems.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.arc_chart_version

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
  wait            = true
}
