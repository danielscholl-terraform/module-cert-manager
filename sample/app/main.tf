resource "helm_release" "sampleapp" {
  name  = (var.name != null ? var.name : "sampleapp")
  chart = "${path.module}/chart"

  namespace        = var.namespace
  create_namespace = var.kubernetes_create_namespace

  values = [<<-EOT
    ingress:
      enabled: true
      annotations:
        kubernetes.io/ingress.class: nginx
        cert-manager.io/cluster-issuer: letsencrypt-issuer-staging
        nginx.ingress.kubernetes.io/rewrite-target: /$1
        nginx.ingress.kubernetes.io/use-regex: "true"
      tls:
        - secretName: tls-secret
          hosts:
            - ${var.domain_name}
      hosts:
        - host: ${var.domain_name}
          paths: ["/(.*)"]
      rules:
      - http:
          paths:
          - backend:
              serviceName: hello-arc
              servicePort: 80
  EOT
  ]
}
