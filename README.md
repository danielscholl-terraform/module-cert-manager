# Kubernetes Cert-Manager Module

## Introduction

This module will install JetStack Lets Encrypt certificate manager into a Kubernetes.

<br />

## Usage

```bash
provider "helm" {
  alias = "aks"
  debug = true
  kubernetes {
    host                   = module.aks.kube_config.host
    username               = module.aks.kube_config.username
    password               = module.aks.kube_config.password
    client_certificate     = base64decode(module.aks.kube_config.client_certificate)
    client_key             = base64decode(module.aks.kube_config.client_key)
    cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
  }
}

module "ssh_key" {
  source = "git::https://github.com/danielscholl-terraform/module-ssh-key?ref=v1.0.0"
}

module "resource_group" {
  source = "git::https://github.com/danielscholl-terraform/module-resource-group?ref=v1.0.0"

  name     = "iac-terraform"
  location = "eastus2"

  resource_tags = {
    iac = "terraform"
  }
}

module "aks" {
  source     = "git::https://github.com/danielscholl-terraform/module-aks?ref=v1.0.0"
  depends_on = [module.resource_group, module.ssh_key]

  name                = format("iac-terraform-cluster-%s", module.resource_group.random)
  resource_group_name = module.resource_group.name
  dns_prefix          = format("iac-terraform-cluster-%s", module.resource_group.random)

  linux_profile = {
    admin_username = "k8sadmin"
    ssh_key        = "${trimspace(module.ssh_key.public_ssh_key)} k8sadmin"
  }

  default_node_pool = "default"
  node_pools = {
    default = {
      vm_size                = "Standard_B2s"
      enable_host_encryption = true

      node_count = 2
    }
  }

  resource_tags = {
    iac = "terraform"
  }
}

module "certs" {
  source     = "../"
  depends_on = [module.aks]

  providers = { helm = helm.aks }

  name                        = format("iac-terraform-cluster-%s", module.resource_group.random)
  namespace                   = "cert-manager"
  kubernetes_create_namespace = true

  issuers = {
    staging = {
      namespace            = "cert-manager"
      cluster_issuer       = true
      email_address        = "admin@email.com"
      letsencrypt_endpoint = "staging"
    }
    production = {
      namespace            = "cert-manager"
      cluster_issuer       = true
      email_address        = "admin@email.com"
      letsencrypt_endpoint = "production"
    }
  }
}
```

<!--- BEGIN_TF_DOCS --->
## Providers

| Name | Version |
|------|---------|
| helm | >=2.4.1 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| additional\_yaml\_config | yaml config for helm chart to be processed last | `string` | `""` | no |
| cert\_manager\_version | cert-manager helm chart version | `string` | `"v0.15.1"` | no |
| helm\_release\_name | helm release name | `string` | `"cert-manager"` | no |
| install\_crds | install cert-manager crds | `bool` | `true` | no |
| issuers | n/a | <pre>map(object({<br>    namespace            = string # kubernetes namespace<br>    cluster_issuer       = bool   # setting 'true' will create a ClusterIssuer, setting 'false' will create a namespace isolated Issuer<br>    email_address        = string # email address used for expiration notification<br>    letsencrypt_endpoint = string # letsencrypt endpoint (https://letsencrypt.org/docs/acme-protocol-updates).  Allowable inputs are 'staging', 'production' or a full URL<br>  }))</pre> | `{}` | no |
| kubernetes\_create\_namespace | create kubernetes namespace if not present | `bool` | `true` | no |
| name | The name of the Kubernetes Cluster. (Optional) - names override | `string` | n/a | yes |
| name\_identifier | allows for unique resources when multiple aks cluster exist in same environment | `string` | `""` | no |
| namespace | kubernetes namespace | `string` | `"cert-manager"` | no |

## Outputs

| Name | Description |
|------|-------------|
| issuers | n/a |
| namespaces | n/a |
<!--- END_TF_DOCS --->