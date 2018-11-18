resource "aws_s3_bucket_object" "object_ssl" {
  bucket  = "${ aws_s3_bucket.vault_resources.id }"
  key     = "ssl/"
  source = "/dev/null"
  depends_on = [
    "aws_s3_bucket.vault_resources"  ]
}
