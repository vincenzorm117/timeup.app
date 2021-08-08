
resource "aws_acm_certificate_validation" "timeup" {
  certificate_arn         = aws_acm_certificate.timeup.arn
  validation_record_fqdns = [for x in aws_route53_record.timeup : x.fqdn]
}


resource "aws_route53_record" "timeup" {
  for_each = {
    for dvo in aws_acm_certificate.timeup.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.timeup.zone_id
}
