resource "aws_route53_record" "vault" {
  zone_id = "${var.vault_dns_zone_id}"
  name    = "vault"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_lb.alb.dns_name}"]
}

data "aws_route53_zone" "vault" {
  name = "hcom-sandbox.net"
}
resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.vault.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.vault.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.vault.zone_id}"
  records = ["${aws_acm_certificate.vault.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}