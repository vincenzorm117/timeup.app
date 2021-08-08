

resource "aws_acm_certificate" "timeup" {
  domain_name               = var.domain
  validation_method         = "DNS"
  subject_alternative_names = ["*.${var.domain}"]
}

