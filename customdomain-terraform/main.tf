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

resource "aws_route53_zone" "eidas_zone" {
  name = "eidas.signin.service.gov.uk"
}

resource "aws_route53_record" "mw-integration" {
  zone_id = aws_route53_zone.eidas_zone.zone_id
  name    = "integration-mw-de.eidas.signin.service.gov.uk"
  type    = "NS"
  ttl     = 3600

  records = [
    "ns-81.awsdns-10.com.",
    "ns-852.awsdns-42.net.",
    "ns-1387.awsdns-45.org.",
    "ns-1765.awsdns-28.co.uk."
  ]
}

resource "aws_route53_record" "mw-staging" {
  zone_id = aws_route53_zone.eidas_zone.zone_id
  name    = "staging-mw-de.eidas.signin.service.gov.uk"
  type    = "NS"
  ttl     = 3600

  records = [
    "ns-1930.awsdns-49.co.uk.",
    "ns-1506.awsdns-60.org.",
    "ns-8.awsdns-01.com.",
    "ns-969.awsdns-57.net."
  ]
}

resource "aws_route53_record" "mw-prod" {
  zone_id = aws_route53_zone.eidas_zone.zone_id
  name    = "prod-mw-de.eidas.signin.service.gov.uk"
  type    = "NS"
  ttl     = 3600

  records = [
    "ns-1770.awsdns-29.co.uk.",
    "ns-984.awsdns-59.net.",
    "ns-1189.awsdns-20.org.",
    "ns-152.awsdns-19.com."
  ]
}

resource "aws_route53_record" "mw-alias" {
  zone_id = aws_route53_zone.eidas_zone.zone_id
  name    = "middleware-de.eidas.signin.service.gov.uk"
  type    = "CNAME"
  ttl     = 300

  records = [
    "middleware.prod-mw-de.eidas.signin.service.gov.uk."
  ]
}

module "staging_proxy_node" {
  source               = "./modules/customdomain"
  aws_account_role_arn = var.aws_account_role_arn
  zone_id              = aws_route53_zone.eidas_zone.zone_id
  govuk_domain         = "proxy-node.test.eidas.signin.service.gov.uk"
  govsvcuk_domain      = "proxy-node.test.verify-eidas-proxy-node-build.london.verify.govsvc.uk"
}

module "integration_proxy_node" {
  source               = "./modules/customdomain"
  aws_account_role_arn = var.aws_account_role_arn
  zone_id              = aws_route53_zone.eidas_zone.zone_id
  govuk_domain         = "proxy-node.integration.eidas.signin.service.gov.uk"
  govsvcuk_domain      = "proxy-node.integration.verify-eidas-proxy-node-deploy.london.verify.govsvc.uk"
}

resource "aws_route53_record" "prod_proxy_node" {
  zone_id = aws_route53_zone.eidas_zone.zone_id
  name    = "proxy-node.eidas.signin.service.gov.uk"
  type    = "CNAME"
  ttl     = 3600

  records = ["proxy-node.production.verify-eidas-proxy-node-deploy.london.verify.govsvc.uk"]
}

module "staging_stub_connector" {
  source               = "./modules/customdomain"
  aws_account_role_arn = var.aws_account_role_arn
  zone_id              = aws_route53_zone.eidas_zone.zone_id
  govuk_domain         = "stub-connector.test.eidas.signin.service.gov.uk"
  govsvcuk_domain      = "stub-connector.test.verify-eidas-proxy-node-build.london.verify.govsvc.uk"
}

module "integration_stub_connector" {
  source               = "./modules/customdomain"
  aws_account_role_arn = var.aws_account_role_arn
  zone_id              = aws_route53_zone.eidas_zone.zone_id
  govuk_domain         = "stub-connector.integration.eidas.signin.service.gov.uk"
  govsvcuk_domain      = "stub-connector.integration.verify-eidas-proxy-node-deploy.london.verify.govsvc.uk"
}

output "eidas_zone_name_servers" {
  value = aws_route53_zone.eidas_zone.name_servers
}
