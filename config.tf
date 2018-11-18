resource "aws_s3_bucket_object" "object" {
  bucket  = "${ aws_s3_bucket.vault_resources.id }"
  key     = "resources/config/config.hcl"
  content = "${ data.template_file.userdata.rendered }"
  etag    = "${ md5( data.template_file.userdata.rendered ) }"

  # Depends on both buckets because we don't want to place until replication is set up
  depends_on = [
    "aws_s3_bucket.vault_resources",
    "aws_s3_bucket.vault_resources_dr"
  ]
}
