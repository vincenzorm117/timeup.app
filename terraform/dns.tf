

resource "aws_route53_zone" "timeup" {
  name = var.domain
  
  tags = local.tags
}

resource "aws_route53_record" "api" {
  name    = aws_api_gateway_domain_name.api.domain_name
  type    = "A"
  zone_id = aws_route53_zone.timeup.id

  alias {
    evaluate_target_health = false
    name                   = aws_api_gateway_domain_name.api.regional_domain_name
    zone_id                = aws_api_gateway_domain_name.api.regional_zone_id
  }
}