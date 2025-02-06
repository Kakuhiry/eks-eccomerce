variable "region" {
  description = "AWS region"
  type        = string
}

variable "name" {
  description = "Cluster name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
}

variable "intra_subnets" {
  description = "Intra subnet CIDRs"
  type        = list(string)
}
