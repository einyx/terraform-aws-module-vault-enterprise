resource "aws_s3_bucket_object" "object_ssl" {
  bucket  = "${ aws_s3_bucket.vault_resources.id }"
  key     = "ssl/"
  source = "/dev/null"
  depends_on = [
    "aws_s3_bucket.vault_resources"  ]
}

resource "aws_acm_certificate" "vault" {
  domain_name       = "${var.vault_dns_address}"
  validation_method = "DNS"
}
resource "aws_acm_certificate_validation" "vault" {
  certificate_arn = "${aws_acm_certificate.vault.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}",
  ]
}