variable "gsp_cluster_state_bucket_name" {
  type = "string"
}

variable "gsp_cluster_state_bucket_key" {
  type = "string"
}

variable "workspace_name" {
  type = "string"
}

variable "vpc_endpoint" {
  type = "string"
}

variable "aws_account_role_arn" {
  type = "string"
}

terraform {
  backend "s3" {}
}

provider "aws" {
  region = "eu-west-2"

  assume_role {
    role_arn = var.aws_account_role_arn
  }
}

data "terraform_remote_state" "gsp_cluster" {
  backend = "s3"

  config = {
    bucket = var.gsp_cluster_state_bucket_name
    key    = var.gsp_cluster_state_bucket_key
    region = "eu-west-2"
  }

  workspace = "${var.workspace_name}"
}

module "psn" {
  source            = "./modules/psn"
  vpc_id            = data.terraform_remote_state.gsp_cluster.outputs.vpc_id
  vpc_endpoint      = var.vpc_endpoint
  subnet_ids        = [data.terraform_remote_state.gsp_cluster.outputs.subnet_ids[0], data.terraform_remote_state.gsp_cluster.outputs.subnet_ids[1]]
  security_group_id = data.terraform_remote_state.gsp_cluster.outputs.worker_security_group_id
}

resource "aws_route53_record" "dcs_dev" {
  zone_id = data.terraform_remote_state.gsp_cluster.outputs.r53_zone_id
  name    = "dcs-dev.${data.terraform_remote_state.gsp_cluster.outputs.cluster_domain}"
  type    = "CNAME"
  ttl     = 3600

  records = ["nlb.${data.terraform_remote_state.gsp_cluster.outputs.cluster_domain}"]
}

output "psn_network_policy_yaml" {
  value = module.psn.psn_network_policy_yaml
}
