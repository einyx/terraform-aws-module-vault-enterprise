data "aws_iam_policy_document" "s3_trust_policy" {
  statement {
    effect = "Allow"

    principals = {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "s3_vault_resources_replicaton_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
    ]

    resources = [
      "${ aws_s3_bucket.vault_resources.arn }",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
    ]

    resources = [
      "${ aws_s3_bucket.vault_resources.arn }/resources/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]

    resources = [
      "${ aws_s3_bucket.vault_resources_dr.arn }/resources/*",
    ]
  }
}

data "aws_iam_policy_document" "s3_vault_data_replicaton_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
    ]

    resources = [
      "${ aws_s3_bucket.vault_data.arn }",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObjectVersion",
      "s3:GetObjectVersionAcl",
    ]

    resources = [
      "${ aws_s3_bucket.vault_data.arn }/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
    ]

    resources = [
      "${ aws_s3_bucket.vault_data_dr.arn }/*",
    ]
  }
}

data "aws_iam_policy_document" "s3_vault_resources_bucket_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl" 

    ]

    principals {
      type        = "AWS"
      identifiers = ["${ data.aws_elb_service_account.elb_sa.arn }"]
    }

    resources = [
      "arn:aws:s3:::${ var.vault_resources_bucket_name }/logs/alb_access_logs/*",
    ]
  }

   statement {
    effect = "Deny"

    actions = [
      "s3:PutObject",
    ]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }

    resources = [
      "arn:aws:s3:::${ var.vault_resources_bucket_name }/ssl/*",
      "arn:aws:s3:::${ var.vault_resources_bucket_name }/ssh_key/*",
      "arn:aws:s3:::${ var.vault_resources_bucket_name }/root_key/*",
      "arn:aws:s3:::${ var.vault_resources_bucket_name }/unseal_keys/*"
    ]
  }
}

############################
## EC2 #####################
############################
data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    effect = "Allow"

    principals = {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

data "aws_iam_policy_document" "vault_ec2_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      "${ aws_s3_bucket.vault_data.arn }",
      "${ aws_s3_bucket.vault_resources.arn }",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      "${ aws_s3_bucket.vault_resources.arn }/resources/*",
      "${ aws_s3_bucket.vault_resources.arn }/ssl/*",
      "${ aws_s3_bucket.vault_resources.arn }/*",

    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]

    resources = [
      "${ aws_s3_bucket.vault_data.arn }/*",
      "${ aws_s3_bucket.vault_resources.arn }/ssl/*",

    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:*",
    ]

    resources = [
      "arn:aws:dynamodb:${ var.region }:${ data.aws_caller_identity.current.account_id }:table/${ var.dynamodb_table_name }",
      "arn:aws:dynamodb:${ var.region }:${ data.aws_caller_identity.current.account_id }:table/${ var.dynamodb_table_name }/*",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances"
    ]

    resources = [
      "*"
    ]
  }


}
