terraform {
  source = "git@github.com:ddriham/final-project-modules.git//addons?ref=addons-v0.0.1"
  
}

include "root" {
  path = find_in_parent_folders()
}

include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

inputs = {
  # argocd
  env                  = include.env.locals.env
  eks_name             = dependency.eks.outputs.eks_name
  enable_argo_cd       = true
  argo_cd_helm_version = "4.10.0"
  argo_cd_namespace    = "argocd"
  argo_cd_ingress_host = "dev-ddriham.argocd"

}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    eks_name = "ddriham-eks-cluster"
  }
}

generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_eks_cluster" "eks" {
  name = var.eks_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.eks_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}
EOF
}
