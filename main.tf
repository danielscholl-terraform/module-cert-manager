##############################################################
# This module allows the installation of Cert Manager
##############################################################

resource "helm_release" "cert_manager" {
  name             = var.helm_release_name
  namespace        = var.namespace
  create_namespace = var.kubernetes_create_namespace
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.cert_manager_version

  values = [
    yamlencode({
      installCRDs = "${var.install_crds}"
    }),
    var.additional_yaml_config
  ]
}

resource "helm_release" "issuer" {
  depends_on = [helm_release.cert_manager]
  for_each   = var.issuers

  name      = "cert-manager-issuer-${each.key}"
  namespace = each.value.namespace
  chart     = "${path.module}/charts"

  values = [
    yamlencode({
      kind       = (each.value.cluster_issuer ? "ClusterIssuer" : "Issuer")
      name       = "letsencrypt-issuer-${each.key}"
      email      = each.value.email_address
      server     = lookup(local.le_endpoint, each.value.letsencrypt_endpoint, each.value.letsencrypt_endpoint)
      secretName = "cert-manager-issuer-${each.key}"
    })
  ]
}
