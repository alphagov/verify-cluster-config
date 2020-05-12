variable "zone_id" {
  type = "string"
}

variable "govuk_domain" {
  type = "string"
}

variable "govsvcuk_domain" {
  type = "string"
}

variable "aws_account_role_arn" {
  type = "string"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"

  assume_role {
    role_arn = var.aws_account_role_arn
  }
}

resource "aws_acm_certificate" "cert" {
  provider          = aws.us-east-1
  domain_name       = var.govuk_domain
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  name    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.cert.domain_validation_options.0.resource_record_type
  zone_id = var.zone_id
  records = [aws_acm_certificate.cert.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert-validation" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

resource "aws_cloudfront_distribution" "cloudfront_dist" {
  enabled          = true
  is_ipv6_enabled  = true
  price_class      = "PriceClass_100" # EU and NA optimised, lower cost
  aliases          = [var.govuk_domain]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert-validation.certificate_arn
    ssl_support_method  = "sni-only"
  }

  origin {
    domain_name = var.govsvcuk_domain
    origin_id   = "gsp"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "gsp"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }
}

resource "aws_route53_record" "record" {
  zone_id = var.zone_id
  name    = var.govuk_domain
  type    = "CNAME"
  ttl     = 3600

  records = [aws_cloudfront_distribution.cloudfront_dist.domain_name]
}

