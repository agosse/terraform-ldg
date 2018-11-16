data "aws_route53_zone" "selected" {
  name = "${var.zone_name}"
}

resource "aws_route53_record" "api" {
  zone_id = "${data.aws_route53_zone.selected.id}"
  name    = "${var.api_dns_prefix}.${var.zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_lb.alb.dns_name}"]
}

resource "aws_route53_record" "www" {
  zone_id = "${data.aws_route53_zone.selected.id}"
  name    = "www.${var.zone_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_cloudfront_distribution.docroot.domain_name}"]
}
