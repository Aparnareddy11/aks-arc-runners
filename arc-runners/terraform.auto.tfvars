subscription_id = "cd225c8e-28e2-485b-8be6-95ea3024d8b7"
tenant_id       = "16b3c013-d300-468d-ac64-7eda0820b6d3"

tf_state_resource_group  = "terraform-state-rg"
tf_state_storage_account = "myteamtfstate"
tf_state_container       = "tfstate"
infra_tf_state_key       = "arc/dev/infra.tfstate"

github_config_url          = "https://github.com/Aparnareddy11"
github_app_id              = "3065029"
github_app_installation_id = "115599835"
runner_image               = "ghcr.io/actions/actions-runner:latest"

runner_scale_set_name = "arc-runner-set"
min_runners           = 0
max_runners           = 10
