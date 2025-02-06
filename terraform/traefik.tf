resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://helm.traefik.io/traefik"
  chart           = "traefik"
  namespace       = "traefik"
  create_namespace = true
  version = "34.2.0"

  values = [file("./helm/traefik/values.yaml")]
  depends_on = [ module.eks.eks_managed_node_groups ]
}