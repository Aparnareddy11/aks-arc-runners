## Description

This repository provisions an Azure Kubernetes Service (AKS) cluster and
deploys GitHub Actions Runner Controller (ARC) with Terraform. ARC creates
isolated, ephemeral self-hosted runners on demand and scales them according to
the configured workload limits. Included GitHub Actions workflows deploy the
infrastructure and runner components separately, then verify the runner scale
set by executing an authenticated Azure CLI job.

## Architecture

Two Terraform root modules separate infrastructure from runner configuration.
The `infra` module deploys a resource group and a public AKS cluster with Azure
RBAC, Azure CNI Overlay networking, autoscaling, OIDC, and workload identity.
The `arc-runners` module reads the AKS outputs from Azure Blob state and deploys
the GitHub Actions Runner Controller (ARC) and one ephemeral runner scale set.

```text
.
|-- infra/
|   `-- aks.tf
|-- arc-runners/
|   |-- arc-controller.tf
|   `-- runners.tf
`-- .github/workflows/
    |-- 01-deploy-aks-arc.yml
    |-- 03-deploy-arc-runners.yml
    `-- 04-test-arc-runner.yml
```

```mermaid
flowchart TB
  GH["GitHub<br/>Repository, organization, or enterprise"]

  subgraph AKS["Azure Kubernetes Service (AKS)"]
    direction TB

    subgraph SYSTEMS["Controller namespace: arc-systems"]
      direction LR
      CONTROLLER{{"ARC<br/>Controller"}}
      LISTENER{{"Listener"}}
    end

    subgraph RUNNERS["Runner namespace: arc-runners"]
      direction TB
      SCALESET{{"Runner<br/>Scale Set"}}

      subgraph PODS[" "]
        direction LR
        RUNNER1["Runner Pod"]
        RUNNER2["Runner Pod"]
        RUNNER3["Runner Pod<br/>(ephemeral)"]
      end
    end
  end

  CONTROLLER -->|"2. Manage"| LISTENER
  SCALESET -->|"4. Create"| RUNNER1
  SCALESET -->|"4. Create"| RUNNER2
  SCALESET -.->|"4. Create"| RUNNER3

  GH -->|"1. Register and long-poll"| SYSTEMS
  SYSTEMS -->|"3. Set desired count"| RUNNERS
  RUNNERS -.->|"5. Run job and report status"| STATUS["GitHub<br/>Job status"]

  classDef control fill:#3277dd,stroke:#1c5bb8,stroke-width:2px,color:#ffffff
  classDef runner fill:#ffffff,stroke:#3277dd,stroke-width:2px,color:#24292f
  classDef ephemeral fill:#dceaff,stroke:#78a9ef,stroke-width:2px,color:#24292f

  class CONTROLLER,LISTENER,SCALESET control
  class RUNNER1,RUNNER2 runner
  class RUNNER3 ephemeral

  style GH fill:#24292f,stroke:#24292f,stroke-width:2px,color:#ffffff
  style STATUS fill:#24292f,stroke:#24292f,stroke-width:2px,color:#ffffff
  style AKS fill:#e8f3ff,stroke:#2589e8,stroke-width:2px,color:#0875cf
  style SYSTEMS fill:#f5f9ff,stroke:#75afe8,stroke-width:2px,color:#4d74a0
  style RUNNERS fill:#f3fbef,stroke:#9acb77,stroke-width:2px,color:#63983f
  style PODS fill:transparent,stroke:transparent
```

The controller and runner workloads use separate namespaces, following GitHub's
security recommendation. Runner pods execute arbitrary workflow code, so this
AKS cluster should not share nodes with sensitive production workloads.

## Prerequisites

* Terraform 1.6 or later
* Azure CLI authenticated with `az login`
* An Azure subscription where you can create a resource group and AKS cluster
* An Azure Blob container for the two Terraform state files
* A GitHub App installed in the account that owns the target organization or
  repository

Configure the GitHub App with these permissions:

* Organization `Self-hosted runners`: read and write
* Repository `Metadata`: read-only
* Repository `Administration`: read and write only for repository-scoped runners

## Configure

Update Azure deployment values in `infra/terraform.auto.tfvars`. Set
`github_config_url`, the GitHub App IDs, Azure authentication values, and
infrastructure state settings in `arc-runners/terraform.auto.tfvars`.

The committed `terraform.auto.tfvars` files contain deployment-specific example
values. Replace the subscription, tenant, naming, state storage, GitHub URL, and
GitHub App values before deployment. The `client_id` input in the runner module
is the Microsoft Entra application ID used to authenticate to the remote state.

Keep the GitHub App private key out of files and shell history. In PowerShell,
load it into a sensitive Terraform environment variable:

```powershell
$env:TF_VAR_github_app_private_key = Get-Content -Raw "C:\secure\arc-app.private-key.pem"
```

> [!IMPORTANT]
> Terraform stores the GitHub App private key in state because it creates the
> Kubernetes secret. Use an encrypted remote backend with restricted access for
> shared or production deployments. Local state and `terraform.tfvars` are
> excluded by `.gitignore`.

Runner pods pull the official GitHub Actions runner image from GitHub Container
Registry by default: `ghcr.io/actions/actions-runner:latest`. No ACR or image
pull secret is required. Set `runner_image` to another full public image
reference when needed.

The official image contains the runner runtime rather than the full software
set available on GitHub-hosted runners. Install workflow-specific tools through
setup actions or workflow steps. Set `runner_container_mode = "dind"` only when
workflows require Docker actions or container jobs. Docker-in-Docker requires
privileged runner pods.

## Deploy

Both Terraform roots declare an `azurerm` backend. Supply the state resource
group, storage account, container, and a distinct key when initializing each
root. Then format, validate, review, and apply the configuration:

```powershell
terraform -chdir=infra fmt
terraform -chdir=infra init `
  -backend-config="resource_group_name=terraform-state-rg" `
  -backend-config="storage_account_name=myteamtfstate" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=arc/dev/infra.tfstate" `
  -backend-config="use_azuread_auth=true"
terraform -chdir=infra validate
terraform -chdir=infra plan -out infra.tfplan
terraform -chdir=infra apply infra.tfplan
```

The first apply can take 10 to 20 minutes while Azure creates AKS.

Deploy ARC after AKS is available:

```powershell
terraform -chdir=arc-runners fmt
terraform -chdir=arc-runners init `
  -backend-config="resource_group_name=terraform-state-rg" `
  -backend-config="storage_account_name=myteamtfstate" `
  -backend-config="container_name=tfstate" `
  -backend-config="key=arc/dev/runners.tfstate" `
  -backend-config="use_azuread_auth=true"
terraform -chdir=arc-runners validate
terraform -chdir=arc-runners plan -out arc-runners.tfplan
terraform -chdir=arc-runners apply arc-runners.tfplan
```

## GitHub Actions pipelines

Three manually triggered workflows deploy and test the environment:

| Workflow                            | Runner              | Purpose                                               |
|-------------------------------------|---------------------|-------------------------------------------------------|
| `Deploy AKS infrastructure`         | `ubuntu-latest`     | Creates or updates the resource group and AKS cluster |
| `Deploy ARC controller and runners` | `ubuntu-latest`     | Deploys the controller and runner scale set           |
| `Test ARC runner with Azure CLI`    | `arc-runner-set`    | Signs in to Azure and lists resource groups           |

Run the workflows in that order. Both deployment workflows pin Terraform
`1.13.1`, validate formatting and configuration, create and apply a saved plan,
and use the same concurrency group to prevent overlapping deployments. The ARC
workflow pulls the runner image configured in
`arc-runners/terraform.auto.tfvars`.

Configure these Terraform variables in `arc-runners/terraform.auto.tfvars`:

| Variable | Example |
|----------|---------|
| `client_id` | `00000000-0000-0000-0000-000000000000` |
| `github_config_url` | `https://github.com/example-org` |
| `github_app_id` | `123456` |
| `github_app_installation_id` | `12345678` |
| `runner_image` | `ghcr.io/actions/actions-runner:latest` |
| `runner_scale_set_name` | `arc-runner-set` |

Configure these GitHub Actions repository variables:

| Variable | Example |
|----------|---------|
| `TF_STATE_RESOURCE_GROUP` | `terraform-state-rg` |
| `TF_STATE_STORAGE_ACCOUNT` | `myteamtfstate` |
| `TF_STATE_CONTAINER` | `tfstate` |
| `INFRA_TF_STATE_KEY` | `arc/dev/infra.tfstate` |
| `ARC_RUNNERS_TF_STATE_KEY` | `arc/dev/runners.tfstate` |

Configure these GitHub Actions repository secrets:

* `AZURE_CLIENT_ID`
* `AZURE_CLIENT_SECRET`
* `AZURE_TENANT_ID`
* `AZURE_SUBSCRIPTION_ID`
* `ARC_GITHUB_APP_PRIVATE_KEY`

The Azure credentials are used by all three workflows. The GitHub App private
key is used only by the ARC deployment workflow.

Grant the service principal the minimum permissions required by your scope and
rotate its client secret regularly. The workflows require permission to manage
the deployment resources and access the state blob. Typical built-in roles are
`Contributor` and `Storage Blob Data Contributor` at their corresponding
scopes. Migrate to GitHub OIDC and a federated identity credential when the
temporary client-secret setup is no longer needed.

The state resource group, storage account, and blob container must exist before
the first Terraform workflow runs. The `infra` and `arc-runners` roots use
separate state blobs. The runner root reads the infra outputs to locate AKS and
does not own the cluster.

> [!IMPORTANT]
> The root-level local Terraform state is retained because it may represent
> deployed resources. Before running either workflow, migrate existing state so
> Azure resources are in `INFRA_TF_STATE_KEY`, while the controller, namespaces,
> GitHub secret, and runner Helm release are in `ARC_RUNNERS_TF_STATE_KEY`.
> Starting with empty or incorrectly split states can make Terraform attempt to
> recreate resources that already exist.

## Verify

Configure `kubectl` and inspect the ARC workloads:

```powershell
az aks get-credentials `
  --resource-group (terraform -chdir=infra output -raw resource_group_name) `
  --name (terraform -chdir=infra output -raw aks_cluster_name) `
  --overwrite-existing

kubectl get pods -n (terraform -chdir=arc-runners output -raw arc_controller_namespace)
kubectl get pods -n (terraform -chdir=arc-runners output -raw arc_runner_namespace)
helm list --all-namespaces
```

Run the `Test ARC runner with Azure CLI` workflow to verify that GitHub can
schedule a job on the scale set and that the runner can authenticate to Azure.
The workflow installs Azure CLI when the runner image does not contain it.

For other jobs, use the value from `terraform -chdir=arc-runners output -raw
runner_scale_set_name` in `runs-on`:

```yaml
jobs:
  build:
    runs-on: arc-runner-set
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on AKS"
```

## Inputs

The commonly changed inputs are:

| Input                      | Default                                 | Purpose                                       |
|----------------------------|-----------------------------------------|-----------------------------------------------|
| `location`                 | `southeastasia`                         | Azure deployment region                       |
| `name_prefix`              | `arc`                                   | Prefix for Azure resource names               |
| `environment`              | `dev`                                   | Environment name used in names and tags       |
| `kubernetes_version`       | `null`                                  | AKS version, or the current Azure default      |
| `aks_sku_tier`             | `Free`                                  | AKS control plane SKU tier                     |
| `node_vm_size`             | `Standard_D4ds_v5`                      | Default node pool VM size                     |
| `node_min_count`           | `1`                                     | Minimum autoscaling node count                |
| `node_max_count`           | `3`                                     | Maximum autoscaling node count                |
| `availability_zones`       | `["2"]`                                 | Default node pool availability zones          |
| `arc_controller_namespace` | `arc-systems`                           | ARC controller namespace                      |
| `arc_runner_namespace`     | `arc-runners`                           | Listener and runner namespace                 |
| `arc_chart_version`        | `0.12.1`                                | Controller and runner scale set chart version |
| `runner_scale_set_name`    | `arc-runner-set`                        | GitHub Actions `runs-on` label                 |
| `min_runners`              | `0`                                     | Minimum idle runner count                     |
| `max_runners`              | `10`                                    | Maximum runner count                          |
| `runner_image`             | `ghcr.io/actions/actions-runner:latest` | Full runner image reference                   |
| `runner_container_mode`    | `null`                                  | Optional ARC container execution mode         |

## Destroy

The AzureRM provider protects a non-empty resource group from accidental
deletion. Destroy child resources first, then run destroy again if Terraform
reports that the resource group still contains Azure-managed resources.

```powershell
terraform -chdir=arc-runners destroy
terraform -chdir=infra destroy
```

ARC chart upgrades can include custom resource definition changes that Helm
cannot update in place. Review the GitHub ARC upgrade guidance before changing
`arc_chart_version`.
