data "aws_caller_identity" "current" {}

variable "kms_key_id" { type= string } 

variable "db_name" { type= string } 

variable "db_username" { type= string }

variable "db_password" { type= string } 

variable "crowdsec_bouncer_api_key" { type= string } 


locals {
  region          = var.region
  name            = var.name
  vpc_cidr        = var.vpc_cidr
  azs             = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  intra_subnets   = var.intra_subnets
  account_id      = data.aws_caller_identity.current.account_id
  tags = {
    Example = local.name
  }
}


terraform {
  backend "s3" {
    bucket = "chicks-state-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
    
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}