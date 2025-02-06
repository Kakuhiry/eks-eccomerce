module "eks-ebs-csi-driver" {
  source  = "lablabs/eks-ebs-csi-driver/aws"
  version = "0.1.2"
  cluster_identity_oidc_issuer = module.eks.oidc_provider
  cluster_identity_oidc_issuer_arn = module.eks.oidc_provider_arn
  
  depends_on = [ module.eks.managed_node_groups ]
}