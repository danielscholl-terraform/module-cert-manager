variable "name" {
  description = "name of helm installation"
  type        = string
  default     = null
}

variable "kubernetes_create_namespace" {
  description = "Create the namespace for the instance if it doesn't yet exist"
  type        = bool
  default     = true
}

variable "namespace" {
  description = "Kubernetes namespace in which to create instance"
  type        = string
  default     = "default"
}

variable "domain_name" {
  description = "FQDN Domain Name"
  type        = string
}
