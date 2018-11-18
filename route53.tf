resource "aws_route53_record" "vault" {
  zone_id = "${var.vault_dns_zone_id}"
  name    = "vault"
  type    = "CNAME"
  ttl     = "60"
  records = ["${aws_lb.alb.dns_name}""]
}
