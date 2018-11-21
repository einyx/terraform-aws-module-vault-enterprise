/* This will get access to the Account ID */
data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "elb_sa" {}

/* The userdata for the instance in the asg */
data "template_file" "userdata" {
  template = "${ file( "${path.module}/files/userdata.sh" ) }"

  vars {
    name_prefix                 = "${ var.name_prefix }"
    region                      = "${ var.region }"
    vault_resources_bucket_name = "${ aws_s3_bucket.vault_resources.id }"
    vault_data_bucket_name      = "${ aws_s3_bucket.vault_data.id }"
    vault_download_url          = "${ var.vault_download_url }"
    vault_license               = "${ var.vault_license }"
    consul_download_url         = "${ var.consul_download_url}"
    vault_config                = "${ var.vault_config }"
    consul_config               = "${ var.consul_config }"
    consul_license              = "${ var.consul_license }"
    vault_extra_install         = "${ var.vault_extra_install }"
    consul_extra_install        = "${ var.consul_extra_install }"
    
  }
}


/* This block converts a standard map of tags to a list of maps of tags for ASGs
*/
data "null_data_source" "asg_tags" {
  count = "${ length( keys( var.tags ) ) }"

  inputs = {
    key                 = "${ element( keys( var.tags ), count.index ) }"
    value               = "${ element( values( var.tags ), count.index ) }"
    propagate_at_launch = true
  }
}
