locals {
  github_secret_name = "arc-github-app"

  runner_scale_set_values = merge(
    {
      githubConfigUrl    = var.github_config_url
      githubConfigSecret = local.github_secret_name
      maxRunners         = var.max_runners
      minRunners         = var.min_runners
      runnerScaleSetName = var.runner_scale_set_name
      template = {
        spec = {
          containers = [
            {
              name    = "runner"
              image   = var.runner_image
              command = ["/home/runner/run.sh"]
            }
          ]
        }
      }
    },
    var.runner_container_mode == null ? {} : {
      containerMode = {
        type = var.runner_container_mode
      }
    }
  )
}
