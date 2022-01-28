provider "azurerm" {
  features {}
}

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

resource "azurerm_public_ip" "main" {
  name                = format("%s-ingress-ip", module.resource_group.name)
  resource_group_name = module.aks.node_resource_group
  location            = module.resource_group.location
  allocation_method   = "Static"

  sku = "Standard"
  tags = {
    iac = "terraform"
  }

  lifecycle {
    ignore_changes = [
      domain_name_label,
      fqdn,
      tags
    ]
  }
}


module "nginx" {
  source     = "git::https://github.com/danielscholl-terraform/module-nginx-ingress?ref=v1.0.0"
  depends_on = [module.aks, module.certs]

  providers = { helm = helm.aks }

  name                        = "ingress-nginx"
  namespace                   = "nginx-system"
  kubernetes_create_namespace = true

  load_balancer_ip = azurerm_public_ip.main.ip_address
  dns_label        = format("sample-%s", module.resource_group.random)
}


module "app" {
  source     = "./app"
  depends_on = [module.nginx]

  providers = { helm = helm.aks }

  namespace                   = "default"
  kubernetes_create_namespace = false
  domain_name                 = format("sample-%s.%s.cloudapp.azure.com", module.resource_group.random, module.resource_group.location)
}

