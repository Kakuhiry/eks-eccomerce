resource "helm_release" "crowdsec-traefik-bouncer" {
  name             = "traefik-bouncer"
  namespace        = "traefik"
  repository       = "https://crowdsecurity.github.io/helm-charts"
  chart           = "crowdsec-traefik-bouncer"
  version         = "0.1.4"
  create_namespace = true

  values = [yamlencode({
    bouncer = {
      crowdsec_bouncer_api_key = "${var.crowdsec_bouncer_api_key}"
      crowdsec_agent_host      = "crowdsec-service.crowdsec.svc.cluster.local:8080"
    }
  })]

  depends_on = [module.eks.eks_managed_node_groups]
}
