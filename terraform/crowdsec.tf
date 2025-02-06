resource "helm_release" "crowdsec" {
  name       = "crowdsec"
  namespace  = "crowdsec"
  repository = "https://crowdsecurity.github.io/helm-charts"
  chart      = "crowdsec"
  version    = "0.17.1"
  create_namespace = true


  values = [
    file("./helm/crowdsec/values.yaml")
  ]
    depends_on = [ module.eks.eks_managed_node_groups ]
}
