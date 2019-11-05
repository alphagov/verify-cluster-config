variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which the endpoint will be used."
}

variable "vpc_endpoint" {
  type        = string
  description = "The service name, in the form com.amazonaws.region.service for AWS services."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The ID of one or more subnets in which to create a network interface for the endpoint."
}

variable "security_group_id" {
  type        = string
  description = "The security group to allow access to the PSN VPC Endpoint."
}

resource "aws_vpc_endpoint" "psn_service" {
  vpc_id            = var.vpc_id
  service_name      = var.vpc_endpoint
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.psn_endpoint.id]

  subnet_ids          = var.subnet_ids
  private_dns_enabled = false
}

resource "aws_security_group" "psn_endpoint" {
  name        = "psn-endpoint"
  description = "The PSN VPC Endpoint"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "psn_ingress_from_worker" {
  security_group_id = aws_security_group.psn_endpoint.id

  type      = "ingress"
  protocol  = "tcp"
  from_port = 3128
  to_port   = 3128

  source_security_group_id = var.security_group_id
}

resource "aws_security_group_rule" "worker_egress_to_psn" {
  security_group_id = var.security_group_id

  type      = "egress"
  protocol  = "tcp"
  from_port = 3128
  to_port   = 3128

  source_security_group_id = aws_security_group.psn_endpoint.id
}

resource "aws_route53_zone" "private" {
  name = "vpc.internal"

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "psn_service" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "psn.${aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_vpc_endpoint.psn_service.dns_entry[0]["dns_name"]]
}

resource "aws_route53_record" "psn_regioned_service" {
  count   = 2
  zone_id = aws_route53_zone.private.zone_id
  name    = "psn.${count.index + 1}.${aws_route53_zone.private.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_vpc_endpoint.psn_service.dns_entry[count.index + 1]["dns_name"]]
}

data "aws_network_interface" "psn_interface" {
  # https://www.terraform.io/docs/configuration/resources.html#using-expressions-in-count
  # count = length(aws_vpc_endpoint.psn_service.network_interface_ids)
  # It's currently 2 in the Verify cluster...so this will do for now
  count = 2

  id = aws_vpc_endpoint.psn_service.network_interface_ids[count.index]
}

output "psn_network_policy_yaml" {
  value = templatefile(
    "${path.module}/data/psn-network-policy.yaml",
    {
      psn_cidrs = jsonencode(formatlist("%s/32", data.aws_network_interface.psn_interface[*].private_ip))
    }
  )
}
