##############################################################
# This module allows the installation of Cert Manager
##############################################################

variable "name" {
  description = "The name of the Kubernetes Cluster. (Optional) - names override"
  type        = string
  default     = null
}

variable "name_identifier" {
  description = "allows for unique resources when multiple aks cluster exist in same environment"
  type        = string
  default     = ""
}

variable "cert_manager_version" {
  description = "cert-manager helm chart version"
  type        = string
  default     = "v0.15.1"
}

variable "helm_release_name" {
  description = "helm release name"
  type        = string
  default     = "cert-manager"
}

variable "namespace" {
  description = "kubernetes namespace"
  type        = string
  default     = "cert-manager"
}

variable "kubernetes_create_namespace" {
  description = "create kubernetes namespace if not present"
  type        = bool
  default     = true
}

variable "additional_yaml_config" {
  description = "yaml config for helm chart to be processed last"
  type        = string
  default     = ""
}

variable "install_crds" {
  description = "install cert-manager crds"
  type        = bool
  default     = true
}

variable "issuers" {
  default = {}
  type = map(object({
    namespace            = string # kubernetes namespace
    cluster_issuer       = bool   # setting 'true' will create a ClusterIssuer, setting 'false' will create a namespace isolated Issuer
    email_address        = string # email address used for expiration notification
    letsencrypt_endpoint = string # letsencrypt endpoint (https://letsencrypt.org/docs/acme-protocol-updates).  Allowable inputs are 'staging', 'production' or a full URL
  }))
}
