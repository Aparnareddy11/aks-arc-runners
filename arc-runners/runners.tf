resource "kubernetes_namespace_v1" "arc_runners" {
  metadata {
    name = var.arc_runner_namespace
    labels = {
      "app.kubernetes.io/part-of" = "actions-runner-controller"
    }
  }
}

resource "kubernetes_secret_v1" "github_app" {
  metadata {
    name      = local.github_secret_name
    namespace = kubernetes_namespace_v1.arc_runners.metadata[0].name
  }

  data = {
    github_app_id              = var.github_app_id
    github_app_installation_id = var.github_app_installation_id
    github_app_private_key     = var.github_app_private_key
  }

  type = "Opaque"
}

resource "helm_release" "arc_runner_set" {
  name       = var.runner_scale_set_name
  namespace  = kubernetes_namespace_v1.arc_runners.metadata[0].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.arc_chart_version

  values = [yamlencode(local.runner_scale_set_values)]

  atomic          = true
  cleanup_on_fail = true
  timeout         = 600
  wait            = true

  depends_on = [
    helm_release.arc_controller,
    kubernetes_secret_v1.github_app,
  ]
}
